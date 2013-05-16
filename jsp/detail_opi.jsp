<%--
 * detail_opi.jsp - Détail d'une OPI Apogée
 *
 * Copyright (C) 2013 Université Paris 1 Panthéon-Sorbonne
 *
 * Auteurs :
 *  VRI   Vincent Rivière
 *
 * Ce fichier est distribué sous licence GPLv3.
 * Voir le fichier license.txt pour les détails.
--%>
<%@ page contentType="text/html" pageEncoding="utf-8" %>
<%@ include file="functions.jsp" %>
<%@ include file="functions_ldap.jsp" %>
<%@ include file="functions_apoharp.jsp" %>
<%@ page import="java.sql.*" %>
<%!
private static class InfosPersoRenderer extends StandardHtmlTableRenderer {
	private static final DateFormat dayDateFormat = new SimpleDateFormat("dd/MM/yyyy");

	public InfosPersoRenderer() {
		super(true);
	}

	public DateFormat getDateFormat(int column) {
		if (column == 4)
			return dayDateFormat;
		else
			return super.getDateFormat(column);
	}

	public boolean getNullIsFailure(int column) {
		if (column == 5 || column == 6) // NNE + clé
			return false; // Le code NNE n'est pas nécessaire pour faire Primo
		else
			return true;
	}
}

private static class EtapesPremiereInscriptionRenderer extends StandardHtmlTableRenderer {
	private String config;

	public EtapesPremiereInscriptionRenderer(String config) {
		super(false);
		this.config = config;
	}

	public void renderCellContent(JspWriter out, ResultSet rs, int column, String value) throws IOException, SQLException {
		if (column == 4 && value != null) {
			String strFind = "code étudiant ";
			int posStartCodeEtu = value.indexOf(strFind);
			if (posStartCodeEtu >= 0) {
				posStartCodeEtu += strFind.length();
				String strStart = value.substring(0, posStartCodeEtu);
				
				int posEndCodeEtu = posStartCodeEtu;
				while (posEndCodeEtu < value.length() && Character.isDigit(value.charAt(posEndCodeEtu)))
					++posEndCodeEtu;
				String strCodeEtu = value.substring(posStartCodeEtu, posEndCodeEtu);
				
				String strEnd = value.substring(posEndCodeEtu);
				
				String url = "detail_etudiant.jsp?config=" + urlEncode(config) + "&cod_etu=" + urlEncode(strCodeEtu);
				out.print(htmlEncode(strStart) + "<a href=\"" + htmlEncode(url) + "\">" + htmlEncode(strCodeEtu) + "</a>" + htmlEncode(strEnd));
				return;
			}
		}

		super.renderCellContent(out, rs, column, value);
	}
}
%>
<%
	if (removeTicketParameter(request, response))
		return;

	String cod_opi_int_epo = request.getParameter("cod_opi_int_epo");

	String query;
	Statement stmt;
	ResultSet rs = null;
	Properties properties = getApplicationProperties();
	String config2 = getConfig(properties, request);
	Connection con = getConnection(request);
	try {
		stmt = con.createStatement();

		query =
			  "select OPI.cod_ind_opi, OPI.lib_nom_pat_ind_opi, OPI.lib_pr1_ind_opi\n"
			+ "from ind_opi OPI\n"
			+ "where OPI.cod_opi_int_epo = '" + sqlEncodeInQuotes(cod_opi_int_epo) + "'";

		boolean etudiantTrouve = false;
		int cod_ind_opi = 0;
		String nom = "";
		String prenom = "";
		try {
			rs = stmt.executeQuery(query);
			if (rs.next()) {
				cod_ind_opi = rs.getInt(1);
				nom = rs.getString(2);
				prenom = rs.getString(3);
				etudiantTrouve = true;
			}
		}
		catch (SQLException e) {
			printSQLException(out, e, query);
		}
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<title><%=htmlEncode(nom + " " + cod_opi_int_epo)%></title>
		<link rel="stylesheet" type="text/css" href="styles.css">
		<script type="text/javascript" src="scripts.js"></script>
	</head>
	<body>
<%
		if (!etudiantTrouve) {
%>	
		<h1><%=htmlEncode(getApplicationPageTitle(properties, con, "OPI " + cod_opi_int_epo + " inexistante"))%></h1>
<%
		}
		else {
%>	
		<h1><%=htmlEncode(getApplicationPageTitle(properties, con, "Détail OPI " + nom + " " + prenom))%></h1>
		<h2>Informations personnelles</h2>
		<!-- COD_IND_OPI = <%=cod_ind_opi%> -->
<%
			query =
				  "select OPI.cod_opi_int_epo, OPI.lib_nom_pat_ind_opi, OPI.lib_pr1_ind_opi, OPI.date_nai_ind_opi, OPI.cod_nne_ind_opi as \"BEA/INE\", OPI.cod_cle_nne_ind_opi as cle, OBA.cod_bac as bac, OBA.daa_obt_bac_oba as date_bac/*, OPI.cod_pop_up1 as pop, OPI.dat_cre_opi_up1*/\n"
				+ "from ind_opi OPI\n"
				+ "left join opi_bac OBA on OBA.cod_ind_opi = OPI.cod_ind_opi\n"
				+ "where OPI.cod_ind_opi = " + cod_ind_opi;

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, new InfosPersoRenderer());
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
		
			// Détection de problèmes sur l'individu OPI
			query =
				  "select OBA.daa_obt_bac_oba\n"
				+ "from ind_opi OPI\n"
				+ "left join opi_bac OBA on OBA.cod_ind_opi = OPI.cod_ind_opi\n"
				+ "where OPI.cod_ind_opi = " + cod_ind_opi;

			try {
				rs = stmt.executeQuery(query);
				rs.next();
				
				String strDateBac = rs.getString("daa_obt_bac_oba");
				if (strDateBac != null && strDateBac.length() > 0 && strDateBac.trim().equals("")) {
%>
			<br>
			<div class="failure">
				Attention&nbsp;: L'année du bac contient des espaces. Si on fait une nouvelle inscription avec Apogée, le bouton OPI va bloquer l'application.
			</div>
<%
				}
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
%>
		<h2>Informations de connexion primo[test].univ-paris1.fr</h2>
<%
			query =
				  "select OPI.cod_opi_int_epo, to_char(OPI.date_nai_ind_opi, 'DDMMYYYY') as DAT_NAI\n"
				+ "from ind_opi OPI\n"
				+ "where OPI.cod_ind_opi = " + cod_ind_opi;

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, false);
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}

%>
		<h2>Etapes susceptibles de première inscription</h2>
<%
			query =
				  "select presel.cod_etp, presel.cod_vrs_vet, VET.lib_web_vet,\n"
				+ "  case\n"
				// Déjà inscrit, en règle
				+ "    when exists (\n"
				+ "      select null\n"
				+ "      from ins_adm_etp IAE\n"
				+ "      where IAE.cod_ind = presel.cod_ind\n"
				+ "        and IAE.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "        and IAE.cod_etp = presel.cod_etp\n"
				+ "        and IAE.cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "        and IAE.eta_iae = 'E'\n"
				+ "        and IAE.eta_pmt_iae = 'P'\n"
				+ "    ) then 'Déjà inscrit cette année avec le code étudiant ' || (select cod_etu from individu where cod_ind = presel.cod_ind) || ', paiement en règle.'\n"
				// Déjà inscrit, en attente de paiement
				+ "    when exists (\n"
				+ "      select null\n"
				+ "      from ins_adm_etp IAE\n"
				+ "      where IAE.cod_ind = presel.cod_ind\n"
				+ "        and IAE.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "        and IAE.cod_etp = presel.cod_etp\n"
				+ "        and IAE.cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "        and IAE.eta_iae = 'E'\n"
				+ "        and IAE.eta_pmt_iae <> 'P'\n"
				+ "    ) then 'Déjà inscrit cette année avec le code étudiant ' || (select cod_etu from individu where cod_ind = presel.cod_ind) || ', en attente de paiement.'\n"
				// Décision OPI défavorable
				+ "    when not presel.cod_dec_veu = 'F'\n"
				+ "      then 'Décision OPI défavorable.'\n"
				// Régime non supporté
				+ "    when not exists (\n"
				+ "      select null\n"
				+ "      from rgi_autoriser_vet RVE\n"
				+ "      where RVE.cod_etp = presel.cod_etp\n"
				+ "        and RVE.cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "        and RVE.cod_rgi = '1'\n"
				+ "    ) then 'Cette étape n''autorise pas le régime d''inscription Formation Initiale. Il faut venir s''inscrire sur place.'\n"
				// Série du bac non renseignée
				+ "    when presel.cod_bac is null\n"
				+ "      then 'Série du bac non renseignée.'\n"
				// Année du bac non renseignée
				+ "    when presel.daa_obt_bac_oba is null\n"
				+ "      then 'Année du bac non renseignée.'\n"
				// Pays de naissance hors service
				+ "    when not exists (\n"
				+ "      select null\n"
				+ "      from pays\n"
				+ "      where cod_pay = presel.cod_pay_nat\n"
				+ "        and tem_en_sve_pay = 'O'\n"
				+ "    ) then 'Pays de nationalité \"' || (select lib_pay from pays where cod_pay = presel.cod_pay_nat) || '\" hors service dans Apogée. Il faut corriger l''OPI de cet étudiant.'\n"
				// Première inscription à distance impossible
				+ "    when VET.cod_cge_minp_vet is null\n"
				+ "      then 'Cette étape n''est pas paramétrée pour la première inscription à distance.'\n"
				// Première inscription à distance pas encore ouverte
				+ "    when VET.dat_deb_minp_vet is not null and to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') < VET.dat_deb_minp_vet\n"
				+ "      then 'La période de première inscription à distance commencera le ' || to_char(VET.dat_deb_minp_vet, 'DD/MM/YYYY') || '.'\n"
				// Première inscription à distance déjà fermée
				+ "    when VET.dat_fin_minp_vet is not null and to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') > VET.dat_fin_minp_vet\n"
				+ "      then 'La période de première inscription à distance s''est terminée le ' || to_char(VET.dat_fin_minp_vet, 'DD/MM/YYYY') || '.'\n"
				// Pas d'objection
				+ "    else 'Pas d''objection connue.'\n"
				+ "  end as situation\n"
				+ "from (\n"
				+ "  select nvl(OPI.cod_ind, (select cod_ind from individu where cod_ind_opi = " + cod_ind_opi + ")) as cod_ind, OPI.cod_pay_nat, VEU.cod_etp, VEU.cod_vrs_vet, VEU.cod_dec_veu, OBA.cod_bac, OBA.daa_obt_bac_oba\n"
				+ "  from (\n"
				+ "    select cod_ind_opi, cod_etp, cod_vrs_vet, cod_dec_veu\n"
				+ "    from voeux_ins\n"
				+ "    where cod_ind_opi = " + cod_ind_opi + "\n"
				+ "    union\n"
				+ "    select cod_ind_opi, cod_etp, cod_vrs_vet, 'F'\n"
				+ "    from telem_laisser_passer_opi\n"
				+ "    where cod_ind_opi = " + cod_ind_opi + "\n"
				+ "  ) VEU\n"
				+ "  left join ind_opi OPI on OPI.cod_ind_opi = VEU.cod_ind_opi\n"
				+ "  left join opi_bac OBA on OBA.cod_ind_opi = VEU.cod_ind_opi\n"
				+ "  where VEU.cod_ind_opi = " + cod_ind_opi + "\n"
				+ ") presel\n"
				// Jointures
				+ "left join version_etape VET on VET.cod_etp = presel.cod_etp and VET.cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "order by presel.cod_etp, presel.cod_vrs_vet";

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, new EtapesPremiereInscriptionRenderer(config2));
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
		}
%>
	</body>
</html>
<%
	}
	finally {
		con.close();
	}
%>
