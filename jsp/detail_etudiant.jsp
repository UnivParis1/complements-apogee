<%--
 * detail_etudiant.jsp - Détail d'un étudiant Apogée
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
		return dayDateFormat;
	}

	public boolean getNullIsFailure(int column) {
		if (column == 7 || column == 8 || column == 9)
			return false;
		else
			return true;
	}

	public void addAdditionalCssClasses(List cssClasses, ResultSet rs, int column, String value) throws SQLException {
		super.addAdditionalCssClasses(cssClasses, rs, column, value);

		if (column == 10 && value != null && value.equals("Attente"))
			cssClasses.add("failure");
	}
}

private static class IaeRenderer extends StandardHtmlTableRenderer {
	public IaeRenderer() {
		super(false);
	}

	public void addAdditionalCssClasses(List cssClasses, ResultSet rs, int column, String value) throws SQLException {
		super.addAdditionalCssClasses(cssClasses, rs, column, value);

		// eta_iae
		if ((column == 8 && value != null && value.equals("C"))
			|| (column == 9 && value != null && value.equals("En cours de création")))
			cssClasses.add("failure");
/*
		// eta_avc_vet
		// FIXME: L'état A ne devrait être une erreur que sur les années précédentes
		if ((column == 13 && value != null && !value.equals("T"))
			|| (column == 14 && value != null && !value.equals("Terminée")))
			cssClasses.add("failure");
*/
		// cod_tre
		if (column == 16 && value == null) {
			String etaAvcVet = rs.getString("ETA_AVC_VET");
			
			if (etaAvcVet != null && etaAvcVet.equals("T"))
				cssClasses.add("failure");
		}

		// lib_tre
		if (column == 17 && value == null) {
			String etaAvcVet = rs.getString("ETA_AVC_VET");
			
			if (etaAvcVet != null && etaAvcVet.equals("T"))
				cssClasses.add("failure");
		}
	}
}

private static class UnicampusRenderer extends StandardHtmlTableRenderer {
	public UnicampusRenderer() {
		super(false);
	}

	public void addAdditionalCssClasses(List cssClasses, ResultSet rs, int column, String value) throws SQLException {
		super.addAdditionalCssClasses(cssClasses, rs, column, value);
		
		// cod_bar_apogee
		if (column == 5) {
			String codeBarresApogee = value;
			String codeBarresUnicampus = rs.getString(4);
			
			if (codeBarresApogee == null || !codeBarresApogee.equals(codeBarresUnicampus))
				cssClasses.add("failure");
		}
	}
}

private static java.util.Date getDaysDateAttribute(Attributes attributes, String name) throws NamingException {
	Attribute attribute = attributes.get(name);
	if (attribute == null)
		return null;

	String strDays = (String)attribute.get();
	int days = Integer.parseInt(strDays);
	GregorianCalendar cal = new GregorianCalendar(1970, 0, 1);
	cal.add(Calendar.DATE, days);
	return cal.getTime();
}

private static String formatDateToDay(java.util.Date date) {
	if (date == null)
		return null;

	DateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy");
	return dateFormat.format(date);
}

private static void printDayTdTag(JspWriter out, java.util.Date date, boolean failure) throws IOException {
	String value = formatDateToDay(date);

	List cssClasses = new ArrayList();

	if (value == null) {
		cssClasses.add("null");
	}

	if (failure)
		cssClasses.add("failure");

	printTdStartTag(out, cssClasses);
	out.print(htmlStringNull(value));
	out.print("</td>");
}
%>
<%
	if (removeTicketParameter(request, response))
		return;

	// Gestion des droits d'accès
	String loginCas = getLoginCas(request);

	String param_cod_etu = request.getParameter("cod_etu");
	int cod_etu = Integer.parseInt(param_cod_etu);

	String query;
	Statement stmt;
	ResultSet rs = null;
	Properties properties = getApplicationProperties();
	Connection con = getConnection(properties, request);
	try {
		stmt = con.createStatement();

		query =
			  "select IND.cod_ind, IND.lib_nom_pat_ind, IND.lib_pr1_ind, 0/*nvl2(PHO.photo, 1, 0)*/\n"
			+ "from individu IND\n"
			//+ "left join up1_photo PHO on PHO.cod_ind = IND.cod_ind\n"
			+ "where IND.cod_etu = " + cod_etu;

		boolean etudiantTrouve = false;
		int cod_ind = 0;
		String nom = "";
		String prenom = "";
		boolean photo = false;
		try {
			rs = stmt.executeQuery(query);
			if (rs.next()) {
				cod_ind = rs.getInt(1);
				nom = rs.getString(2);
				prenom = rs.getString(3);
				photo = rs.getBoolean(4);
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
		<title><%=htmlEncode(nom + " " + cod_etu)%></title>
		<link rel="stylesheet" type="text/css" href="styles.css">
		<script type="text/javascript" src="scripts.js"></script>
	</head>
	<body>
<%
		if (!etudiantTrouve) {
%>	
		<h1><%=htmlEncode(getApplicationPageTitle(properties, con, "Etudiant " + cod_etu + " inexistant"))%></h1>
<%
		}
		else {
%>	
		<table width="100%" cellpadding="0" cellspacing="0">
			<tr>
				<td>
		<h1><%=htmlEncode(getApplicationPageTitle(properties, con, "Détail étudiant " + nom + " " + prenom))%></h1>
		<h2>Informations personnelles</h2>
		<!-- COD_IND = <%=cod_ind%> -->
<%
			query =
				  "select IND.cod_etu, IND.lib_nom_pat_ind, IND.lib_pr1_ind, IND.date_nai_ind, IND.cod_nne_ind, IND.cod_cle_nne_ind as CLE, ADR.num_tel, ADR.num_tel_port, ADR.adr_mail, SIM.lic_sim\n"
				+ "from individu IND\n"
				+ "left join adresse ADR on ADR.cod_ind = IND.cod_ind\n"
				+ "left join sit_mil SIM on SIM.cod_sim = IND.cod_sim\n"
				+ "where IND.cod_ind = " + cod_ind;

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, new InfosPersoRenderer());
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
%>
		<h2>Inscriptions administratives aux années universitaires</h2>
				</td>
				<td align="right">
<%			if (photo) { %>
				<img src="photo.jsp?config=<%=htmlEncode(urlEncode(getConfig(properties, request)))%>&amp;cod_etu=<%=cod_etu%>" width="160" height="200" alt="Photo">
<%			} else { %>
				&nbsp;
<%			} %>
				</td>
			</tr>
		</table>
<%
			query =
				  "select IAA.cod_anu, IAA.cod_rgi, RGI.lib_rgi, ADR.num_tel, ADR.num_tel_port, ADR.adr_mail\n"
				+ "from ins_adm_anu IAA\n"
				+ "left join regime_ins RGI on RGI.cod_rgi = IAA.cod_rgi\n"
				+ "left join adresse ADR on ADR.cod_ind_ina = IAA.cod_ind and ADR.cod_anu_ina = IAA.cod_anu\n"
				+ "where IAA.cod_ind = " + cod_ind + "\n"
				+ "  and IAA.cod_anu = (\n"
				+ "    select max(cod_anu)\n"
				+ "    from ins_adm_anu\n"
				+ "    where cod_ind = IAA.cod_ind\n"
				+ "  )\n"
				+ "order by IAA.cod_anu desc";

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, false);
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
%>
		<h2>Inscriptions administratives aux étapes</h2>
<%
			query =
				  "select P.cod_anu, P.cod_etp, P.cod_vrs_vet, P.lib_web_vet, P.dat_cre_iae, P.cod_cge, P.cod_uti, P.eta_iae,\n"
				+ "  case P.eta_iae\n"
				+ "    when 'A' then 'Annulé'\n"
				+ "    when 'E' then 'En cours'\n"
				+ "    when 'R' then 'Résilié'\n"
				+ "    when 'C' then 'En cours de création'\n"
				+ "    else '?'\n"
				+ "  end as lib_eta_iae,\n"
				+ "  P.eta_pmt_iae,\n"
				+ "  case P.eta_pmt_iae\n"
				+ "    when 'A' then 'En attente de paiement'\n"
				+ "    when 'C' then '?'\n"
				+ "    when 'P' then 'Payée'\n"
				+ "    when 'V' then '?'\n"
				+ "    else '?'\n"
				+ "  end as lib_eta_iae,\n"
				+ "  P.cod_ses,\n"
				+ "  GVT.eta_avc_vet,\n"
				+ "  case GVT.eta_avc_vet\n"
				+ "    when 'A' then 'Avant'\n"
				+ "    when 'T' then 'Terminée'\n"
				+ "    when 'E' then 'Modifiable'\n"
				+ "    else '?'\n"
				+ "  end as deliberation,\n"
				+ "  RVT.not_vet, RVT.cod_tre, TRE.lib_tre\n"
				+ "from (\n"
				+ "  select IAE.cod_ind, IAE.cod_anu, IAE.cod_etp, IAE.cod_vrs_vet, VET.lib_web_vet, IAE.dat_cre_iae, IAE.cod_cge, IAE.cod_uti, IAE.eta_iae, IAE.eta_pmt_iae,\n"
				+ "    case\n"
				+ "      when VET.tem_ses_uni = 'O' then 0\n"
				+ "      when exists (\n"
				+ "        select null\n"
				+ "        from resultat_vet RVT\n"
				+ "        where RVT.cod_ind = IAE.cod_ind and RVT.cod_anu = IAE.cod_anu and RVT.cod_etp = IAE.cod_etp and RVT.cod_vrs_vet = IAE.cod_vrs_vet and RVT.cod_adm = 1 and RVT.cod_ses = 2 and RVT.cod_tre is not null\n"
				+ "      ) then 2\n"
				+ "      else 1\n"
				+ "    end as cod_ses\n"
				+ "  from ins_adm_etp IAE\n"
				+ "  left join version_etape VET on VET.cod_etp = IAE.cod_etp and VET.cod_vrs_vet = IAE.cod_vrs_vet\n"
				+ "  where IAE.cod_ind = " + cod_ind + "\n"
				+ "    and IAE.eta_iae in ('E', 'C')\n"
				+ "    and (IAE.eta_pmt_iae = 'P' or IAE.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O'))\n"
				+ ") P\n"
				+ "left join resultat_vet RVT on RVT.cod_ind = P.cod_ind and RVT.cod_anu = P.cod_anu and RVT.cod_etp = P.cod_etp and RVT.cod_vrs_vet = P.cod_vrs_vet and RVT.cod_adm = 1 and RVT.cod_ses = P.cod_ses\n"
				+ "left join typ_resultat TRE on TRE.cod_tre = RVT.cod_tre\n"
				+ "left join grp_resultat_vet GVT on GVT.cod_etp = P.cod_etp and GVT.cod_vrs_vet = P.cod_vrs_vet and GVT.cod_anu = P.cod_anu and GVT.cod_ses = P.cod_ses and GVT.cod_adm = 1\n"
				+ "order by P.cod_anu desc, P.cod_etp, P.cod_vrs_vet";

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, new IaeRenderer());
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
%>
		<h2>Interdictions explicites sur inscriptions</h2>
<%
			query =
				  "select IBL.cod_etp, IBL.cod_blo, BLO.lib_blo, BLO.cod_tpb, TPB.lib_tpb, IBL.dat_deb_blo, IBL.dat_fin_blo, IBL.lib_cmt_blo\n"
				+ "from ind_sanctionne_blo IBL\n"
				+ "left join blocage BLO on BLO.cod_blo = IBL.cod_blo\n"
				+ "left join typ_blocage TPB on TPB.cod_tpb = BLO.cod_tpb\n"
				+ "where IBL.cod_ind = " + cod_ind + "\n"
				+ "  and BLO.cod_tpb in ('A', 'T')\n"
				+ "  and (IBL.dat_deb_blo is null or TO_DATE(TO_CHAR(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') >= IBL.dat_deb_blo)\n"
				+ "  and (IBL.dat_fin_blo is null or TO_DATE(TO_CHAR(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') <= IBL.dat_fin_blo)\n"
				+ "order by IBL.cod_etp, IBL.cod_blo";

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, false);
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
%>
		<h2>Laissez-passers pour l'année en cours</h2>
<%
			query =
				  "select LPA.cod_anu, LPA.cod_etp, LPA.cod_vrs_vet, VET.lib_web_vet, LPA.dat_cre_lpa, LPA.cod_uti_cre_lpa, LPA.lib_cmt_lpa\n"
				+ "from telem_laisser_passer LPA\n"
				+ "left join version_etape VET on VET.cod_etp = LPA.cod_etp and VET.cod_vrs_vet = LPA.cod_vrs_vet\n"
				+ "where LPA.cod_ind = " + cod_ind + "\n"
				+ "  and LPA.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "order by LPA.cod_anu, LPA.cod_etp, LPA.cod_vrs_vet";

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, false);
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
%>
<%--
		<h2>Informations LDAP / ENT / Malix</h2>
<%
			boolean active = false;
			boolean expire = false;
			DirContext rootContextParis1 = getRootContextParis1();
			try {
				Attributes attributes = getAttributesEtudiantParis1(rootContextParis1, cod_etu, new String[] { "uid", "mail", "shadowLastChange", "shadowExpire" });
				String login = null;
				String mail = null;
				java.util.Date lastChange = null;
				java.util.Date dateExpire = null;
				if (attributes != null) {
					login = (String)attributes.get("uid").get();
					mail = (String)attributes.get("mail").get();
					lastChange = getDaysDateAttribute(attributes, "shadowLastChange");
					active = (lastChange != null);
					dateExpire = getDaysDateAttribute(attributes, "shadowExpire");
					expire = (dateExpire != null && dateExpire.before(new java.util.Date()));
				}
%>
		<table class="resultset">
			<tr>
				<th>LOGIN</th>
				<th>MAIL</th>
				<th>ACTIVATION</th>
				<th>EXPIRATION</th>
			</tr>
			<tr onclick="toggleSelect(this)">
				<%printStandardTdTag(out, login, true);%>
				<%printStandardTdTag(out, mail, true);%>
				<%printDayTdTag(out, lastChange, lastChange == null);%>
				<%printDayTdTag(out, dateExpire, dateExpire == null || expire);%>
			</tr>
		</table>
<%
			}
			finally {
				rootContextParis1.close();
			}
%>

		<h2>Cartes d'étudiant dans Uni'Campus</h2>
<%
			// Problèmes de perfs dès qu'on met des left join
			query =
				  "select c.date_attribution, c.date_delivrance, c.duree_vie, s.codebar as cod_bar_unicampus, PHO.cod_bar as cod_bar_apogee, o.nom as \"OP NOM\", o.prenom as \"OP PRENOM\"\n"
				+ "from porteur@unicampus_prod.world p\n"
				+ "inner join cartes@unicampus_prod.world c on c.id_carte = p.id_carte\n"
				+ "inner join supporte@unicampus_prod.world s on s.id_carte = p.id_carte\n"
				+ "left join up1_photo PHO on PHO.cod_ind = " + cod_ind + "\n"
				+ "inner join operateur@unicampus_prod.world o on o.id_operateur = c.id_operateur\n"
				+ "where p.id_personne = to_char(" + cod_etu + ") || 'Apog0751717J'\n"
				+ "  and c.statut = 'ACTIF'\n"
				+ "order by c.date_attribution desc";

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, new UnicampusRenderer());
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
%>
--%>
		<h2>Informations de connexion reins[test]2.univ-paris1.fr</h2>
<%
			query =
				  "select IND.cod_etu, to_char(IND.date_nai_ind, 'DDMMYYYY') as DAT_NAI\n"
				+ "from individu IND\n"
				+ "where IND.cod_ind = " + cod_ind;

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, false);
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}

%>
		<h2>Etapes susceptibles de réinscription</h2>
<%
			String messagePasObjection;
			if (false/*expire*/)
				messagePasObjection = "Impossible d'accéder à Réins via le CAS car le compte Paris 1 a expiré. Il faut faire un laissez-passer et attendre le lendemain, ou déposer une candidature dans Sésame.";
			else if (false/*!active*/)
				messagePasObjection = "Pas d'objection connue, mais il faut d'abord activer le compte Paris 1.";
			else
				messagePasObjection = "Pas d'objection connue.";

			query =
				  "select distinct presel.cod_etp, presel.cod_vrs_vet, VET.lib_web_vet,\n"
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
				+ "    ) then 'Déjà inscrit cette année, paiement en règle.'\n"
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
				+ "    ) then 'Déjà inscrit cette année, en attente de paiement. Il est possible de refaire Réins et éventuellement de payer en ligne.'\n"
				// Jamais eu d'inscription en règle
				+ "    when not exists (\n"
				+ "      select null\n"
				+ "      from ins_adm_etp IAE\n"
				+ "      where IAE.cod_ind = presel.cod_ind\n"
				+ "        and IAE.eta_iae = 'E'\n"
				+ "        and IAE.eta_pmt_iae = 'P'\n"
				+ "    ) then 'Etudiant déjà dans Apogée mais jamais eu d''inscription en règle. Il faut venir s''inscrire sur place au SIA.'\n"
				// Inscription à l'année universitaire annulée
				+ "    when exists (\n"
				+ "      select null\n"
				+ "      from ins_adm_anu IAA\n"
				+ "      where IAA.cod_ind = presel.cod_ind\n"
				+ "        and IAA.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "        and IAA.eta_iaa = 'A'\n"
				+ "    ) then 'Inscription à l''année universitaire annulée. Il faut venir s''inscrire sur place au SIA.'\n"
				// Code NNE manquant
				+ "    when IND.cod_nne_ind is null or IND.cod_cle_nne_ind is null then 'Code INE/BEA manquant.'\n"
				// Réinscription à distance impossible (population primo)
				+ "    when IND.daa_etb = (select cod_anu from annee_uni where eta_anu_iae = 'O') and VET.cod_cge_minp_vet is null\n"
				+ "      then 'Cette étape n''est pas paramétrée pour la réinscription à distance (population primo).'\n"
				// Réinscription à distance pas encore ouverte (population primo)
				+ "    when IND.daa_etb = (select cod_anu from annee_uni where eta_anu_iae = 'O') and VET.dat_deb_minp_vet is not null and to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') < VET.dat_deb_minp_vet\n"
				+ "      then 'La période de réinscription à distance commencera le ' || to_char(VET.dat_deb_minp_vet, 'DD/MM/YYYY') || ' (population primo).'\n"
				// Réinscription à distance déjà fermée (population primo)
				+ "    when IND.daa_etb = (select cod_anu from annee_uni where eta_anu_iae = 'O') and VET.dat_fin_minp_vet is not null and to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') > VET.dat_fin_minp_vet\n"
				+ "      then 'La période de réinscription à distance s''est terminée le ' || to_char(VET.dat_fin_minp_vet, 'DD/MM/YYYY') || ' (population primo).'\n"
				// Réinscription à distance impossible (population réins)
				+ "    when VET.cod_cge_min_vet is null\n"
				+ "      then 'Cette étape n''est pas paramétrée pour la réinscription à distance (population réins).'\n"
				// Réinscription à distance pas encore ouverte (population réins)
				+ "    when VET.dat_deb_min_vet is not null and to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') < VET.dat_deb_min_vet\n"
				+ "      then 'La période de réinscription à distance commencera le ' || to_char(VET.dat_deb_min_vet, 'DD/MM/YYYY') || ' (population réins).'\n"
				// Réinscription à distance déjà fermée (population réins)
				+ "    when VET.dat_fin_min_vet is not null and to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') > VET.dat_fin_min_vet\n"
				+ "      then 'La période de réinscription à distance s''est terminée le ' || to_char(VET.dat_fin_min_vet, 'DD/MM/YYYY') || ' (population réins).'\n"
				// Changement de régime
				+ "    when not exists (\n"
				+ "      select null\n"
				+ "      from rgi_autoriser_vet RVE\n"
				+ "      where cod_etp = presel.cod_etp\n"
				+ "        and cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "        and cod_rgi = (\n"
				+ "          select cod_rgi\n"
				+ "          from ins_adm_anu IAA\n"
				+ "          where cod_ind = presel.cod_ind\n"
				+ "            and cod_anu = (\n"
				+ "              select max(cod_anu)\n"
				+ "              from ins_adm_anu\n"
				+ "              where cod_ind = IAA.cod_ind\n"
				+ "            )\n"
				+ "        )\n"
				+ "    ) then 'Changement de régime d''inscription impossible via Réins. Il faut venir s''inscrire sur place.'\n"
				// Interdiction explicite
				+ "    when IBL.cod_blo is not null then 'Interdiction \"' || BLO.lib_blo || '\".'\n"
				// Nombre d'inscriptions cette année
				+ "    when exists (select null from regle_gestion where cod_rgg = 'TE06' and tem_act_rgg = 'O')\n"
				+ "      and (\n"
				+ "        select count(*)\n"
				+ "        from ins_adm_etp IAE\n"
				+ "        where IAE.cod_ind = presel.cod_ind\n"
				+ "          and IAE.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "          and IAE.eta_iae <> 'A'\n"
				+ "      ) >= (select par1_rgg from regle_gestion where cod_rgg = 'TE06') then 'Dépassement des ' || (select par1_rgg from regle_gestion where cod_rgg = 'TE06') || ' inscriptions autorisées en ' || (select cod_anu from annee_uni where eta_anu_iae = 'O') || '. Il faut venir s''inscrire sur place au SIA.'\n"
				// Laissez-passer
				+ "    when exists (\n"
				+ "      select null\n"
				+ "      from telem_laisser_passer LPA\n"
				+ "      where LPA.cod_ind = presel.cod_ind\n"
				+ "        and LPA.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "        and LPA.cod_etp = presel.cod_etp and LPA.cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "    ) then 'Pas d''objection connue (laissez-passer).'\n"
				// Nombre d'inscriptions à l'étape
				+ "    when (\n"
				+ "      select count(*)\n"
				+ "      from ins_adm_etp IAE\n"
				+ "      where IAE.cod_ind = presel.cod_ind\n"
				+ "        and IAE.cod_etp = presel.cod_etp\n"
				+ "        and IAE.eta_iae <> 'A'\n"
				+ "    ) >= ETP.nbr_max_iae_aut then 'Nombre d''inscriptions à l''étape limité à ' || ETP.nbr_max_iae_aut || '. Si dérogation, il faut faire un laissez-passer.'\n"
				// Règle des 3i
				+ "    when exists (select null from regle_gestion where cod_rgg = 'IA07' and tem_act_rgg = 'O')\n"
				+ "      and DIP.cod_tpd_etb = (select par2_rgg from regle_gestion where cod_rgg = 'IA07')\n"
				+ "      and (\n"
				+ "        select count(*)\n"
				+ "        from ins_adm_etp IAE\n"
				+ "        left join vdi_fractionner_vet VDE on VDE.cod_dip = IAE.cod_dip and VDE.cod_vrs_vdi = IAE.cod_vrs_vdi and VDE.cod_etp = IAE.cod_etp and VDE.cod_vrs_vet = IAE.cod_vrs_vet\n"
				+ "        left join diplome DIP on DIP.cod_dip = VDE.cod_dip\n"
				+ "        where IAE.cod_ind = presel.cod_ind\n"
				+ "          and IAE.eta_iae <> 'A'\n"
				+ "          and DIP.cod_tpd_etb = (select par2_rgg from regle_gestion where cod_rgg = 'IA07')\n"
				+ "      ) >= (select to_number(par1_rgg) from regle_gestion where cod_rgg = 'IA07')\n"
				+ "      then 'Interdiction implicite : règle des 3i. Si dérogation, il faut faire un laissez-passer.'\n"
				// IA complémentaire sur résultats sans laissez-passer
				+ "    when exists (\n"
				+ "      select null\n"
				+ "      from ins_adm_etp\n"
				+ "      where cod_ind = presel.cod_ind\n"
				+ "        and cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "        and eta_iae = 'E'\n"
				+ "        and eta_pmt_iae = 'P'\n"
				+ "    ) and not exists (\n"
				+ "      select null\n"
				+ "      from telem_laisser_passer\n"
				+ "      where cod_ind = presel.cod_ind\n"
				+ "        and cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "        and cod_etp = presel.cod_etp\n"
				+ "        and cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "    ) then 'Impossible de faire une IA complémentaire sur résultats. Il faut créer un laissez-passer.'\n"
				// Délibération de l'étape donnant accès pas à l'état T
				+ "    when (select tem_reins_sans_delib\n"
				+ "          from version_etape\n"
				+ "          where cod_etp = presel.cod_etp and cod_vrs_vet = presel.cod_vrs_vet) = 'N'\n"
				+ "      and presel.cod_etp_prm is not null\n"
				+ "      and not exists (\n"
				+ "    	   select null\n"
				+ "    	   from grp_resultat_vet\n"
				+ "    	   where cod_etp = presel.cod_etp_prm\n"
				+ "    	     and cod_vrs_vet = presel.cod_vrs_vet_prm\n"
				+ "    	     and cod_anu = presel.cod_anu_prm\n"
				+ "    	     and cod_ses = presel.cod_ses\n"
				+ "    	     and cod_adm = 1\n"
				+ "    	     and eta_avc_vet = 'T'\n"
				+ "    ) then 'Impossible de s''inscrire car la délibération à l''étape ' || presel.cod_etp_prm || ' en ' || presel.cod_anu_prm || (case when presel.cod_ses > 0 then ' session ' || presel.cod_ses end) || ' n''est pas à l''état T. La composante doit passer cette délibération à l''état T, autoriser la réinscription sans délibération à cette étape, ou faire un laissez-passer à l''étudiant.'\n"
				// Résultat à l'étape donnant accès non saisi (hors redoublement)
				+ "    when not (presel.cod_etp = presel.cod_etp_prm and presel.cod_vrs_vet = presel.cod_vrs_vet_prm)\n"
				+ "      and (select tem_reins_sans_delib\n"
				+ "           from version_etape\n"
				+ "           where cod_etp = presel.cod_etp and cod_vrs_vet = presel.cod_vrs_vet) = 'N'\n"
				+ "      and presel.cod_etp_prm is not null\n"
				+ "      and not exists (\n"
				+ "    	   select null\n"
				+ "    	   from resultat_vet\n"
				+ "    	   where cod_ind = presel.cod_ind\n"
				+ "          and cod_etp = presel.cod_etp_prm\n"
				+ "    	     and cod_vrs_vet = presel.cod_vrs_vet_prm\n"
				+ "    	     and cod_anu = presel.cod_anu_prm\n"
				+ "    	     and cod_ses = presel.cod_ses\n"
				+ "    	     and cod_adm = 1\n"
				+ "    	     and cod_tre is not null\n"
				+ "    ) then 'Impossible de s''inscrire car il n''y a pas de résultat positif saisi sur l''étape ' || presel.cod_etp_prm || ' en ' || presel.cod_anu_prm || (case when presel.cod_ses > 0 then ' session ' || presel.cod_ses end) || '. La composante doit saisir un résultat.'\n"
				// Pas d'objection
				+ "    else '" + sqlEncodeInQuotes(messagePasObjection) + "'\n"
				+ "  end as situation\n"
				//+ "  ,presel.cod_etp_prm, presel.cod_vrs_vet_prm, presel.cod_ses\n"
				+ "from (\n"
				// Etapes accessibles via laissez-passer
				+ "  select distinct LPA.cod_ind, LPA.cod_etp, LPA.cod_vrs_vet, null as cod_etp_prm, null as cod_vrs_vet_prm, null as cod_anu_prm, null as cod_ses\n"
				+ "  from telem_laisser_passer LPA\n"
				+ "  where LPA.cod_ind = " + cod_ind + "\n"
				+ "    and LPA.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "  union\n"
				// Etapes accessibles par redoublement (si pas de changement de version)
				+ "  select distinct IAE.cod_ind, IAE.cod_etp, IAE.cod_vrs_vet, IAE.cod_etp as cod_etp_prm, IAE.cod_vrs_vet as cod_vrs_vet_prm, IAE.cod_anu as cod_anu_prm,\n"
				+ "    case\n"
				+ "      when VET.tem_ses_uni = 'O' then 0\n"
				+ "      when exists (\n"
				+ "        select null\n"
				+ "        from resultat_vet RVT\n"
				+ "        where RVT.cod_ind = IAE.cod_ind and RVT.cod_anu = IAE.cod_anu and RVT.cod_etp = IAE.cod_etp and RVT.cod_vrs_vet = IAE.cod_vrs_vet and RVT.cod_adm = 1 and RVT.cod_ses = 2 and RVT.cod_tre is not null\n"
				+ "      ) then 2\n"
				+ "      else 1\n"
				+ "    end as cod_ses\n"
				+ "  from ins_adm_etp IAE\n"
				+ "  inner join version_etape VET on VET.cod_etp = IAE.cod_etp and VET.cod_vrs_vet = IAE.cod_vrs_vet\n"
				+ "  where IAE.cod_ind = " + cod_ind + "\n"
				+ "    and IAE.eta_iae = 'E'\n"
				+ "    and IAE.eta_pmt_iae = 'P'\n"
				+ "    and not exists (\n" // Et qu'il n'existe pas d'étape correspondante
				+ "      select null\n"
				+ "      from vdivet_correspond_vdivet VCV\n"
				+ "      where VCV.cod_dip_old = IAE.cod_dip and VCV.cod_vrs_vdi_old = IAE.cod_vrs_vdi and VCV.cod_etp_old = IAE.cod_etp and VCV.cod_vrs_vet_old = IAE.cod_vrs_vet\n"
				+ "    )\n"
				+ "    and not exists (\n" // Et qu'il n'existe pas de résultat positif à l'étape donnant accès
				+ "      select null\n"
				+ "      from resultat_vet RVT\n"
				+ "      inner join typ_resultat TRE on TRE.cod_tre = RVT.cod_tre\n"
				+ "      where RVT.cod_ind = IAE.cod_ind and RVT.cod_anu = IAE.cod_anu and RVT.cod_etp = IAE.cod_etp and RVT.cod_vrs_vet = IAE.cod_vrs_vet and RVT.cod_adm = 1 and TRE.cod_neg_tre = 1\n"
				+ "    )\n"
				+ "    and not exists (\n" // Et qu'il n'existe pas de résultat positif à l'étape correspondante (sans tenir compte de la version ni de l'année)
				+ "      select null\n"
				+ "      from resultat_vet RVT\n"
				+ "      inner join typ_resultat TRE on TRE.cod_tre = RVT.cod_tre\n"
				+ "      where RVT.cod_ind = IAE.cod_ind and RVT.cod_etp = IAE.cod_etp and RVT.cod_adm = 1 and TRE.cod_neg_tre = 1\n"
				+ "    )\n"
				+ "  union\n"
				// Etapes accessibles par redoublement (si changement de version)
				+ "  select distinct IAE.cod_ind, VCV.cod_etp_new, VCV.cod_vrs_vet_new, IAE.cod_etp as cod_etp_prm, IAE.cod_vrs_vet as cod_vrs_vet_prm, IAE.cod_anu as cod_anu_prm,\n"
				+ "    case\n"
				+ "      when VET.tem_ses_uni = 'O' then 0\n"
				+ "      when exists (\n"
				+ "        select null\n"
				+ "        from resultat_vet RVT\n"
				+ "        where RVT.cod_ind = IAE.cod_ind and RVT.cod_anu = IAE.cod_anu and RVT.cod_etp = IAE.cod_etp and RVT.cod_vrs_vet = IAE.cod_vrs_vet and RVT.cod_adm = 1 and RVT.cod_ses = 2 and RVT.cod_tre is not null\n"
				+ "      ) then 2\n"
				+ "      else 1\n"
				+ "    end as cod_ses\n"
				+ "  from ins_adm_etp IAE\n"
				+ "  inner join vdivet_correspond_vdivet VCV on VCV.cod_dip_old = IAE.cod_dip and VCV.cod_vrs_vdi_old = IAE.cod_vrs_vdi and VCV.cod_etp_old = IAE.cod_etp and VCV.cod_vrs_vet_old = IAE.cod_vrs_vet\n"
				+ "  inner join version_etape VET on VET.cod_etp = IAE.cod_etp and VET.cod_vrs_vet = IAE.cod_vrs_vet\n"
				+ "  where IAE.cod_ind = " + cod_ind + "\n"
				+ "    and IAE.eta_iae = 'E'\n"
				+ "    and IAE.eta_pmt_iae = 'P'\n"
				+ "    and not exists (\n" // Et qu'il n'existe pas de résultat positif à l'étape donnant accès
				+ "      select null\n"
				+ "      from resultat_vet RVT\n"
				+ "      inner join typ_resultat TRE on TRE.cod_tre = RVT.cod_tre\n"
				+ "      where RVT.cod_ind = IAE.cod_ind and RVT.cod_anu = IAE.cod_anu and RVT.cod_etp = IAE.cod_etp and RVT.cod_vrs_vet = IAE.cod_vrs_vet and RVT.cod_adm = 1 and TRE.cod_neg_tre = 1\n"
				+ "    )\n"
				+ "    and not exists (\n" // Et qu'il n'existe pas de résultat positif à l'étape correspondante (sans tenir compte de la version ni de l'année)
				+ "      select null\n"
				+ "      from resultat_vet RVT\n"
				+ "      inner join typ_resultat TRE on TRE.cod_tre = RVT.cod_tre\n"
				+ "      where RVT.cod_ind = IAE.cod_ind and RVT.cod_etp = VCV.cod_etp_new and RVT.cod_adm = 1 and TRE.cod_neg_tre = 1\n"
				+ "    )\n"
				+ "  union\n"
				// Etapes accessibles sur résultat
				+ "  select distinct IAE.cod_ind, VPV.cod_etp, VPV.cod_vrs_vet, VPV.cod_etp_prm, VPV.cod_vrs_vet_prm, IAE.cod_anu as cod_anu_prm,\n"
				+ "    case\n"
				+ "      when VET.tem_ses_uni = 'O' then 0\n"
				+ "      when exists (\n"
				+ "        select null\n"
				+ "        from resultat_vet RVT\n"
				+ "        where RVT.cod_ind = IAE.cod_ind and RVT.cod_anu = IAE.cod_anu and RVT.cod_etp = IAE.cod_etp and RVT.cod_vrs_vet = IAE.cod_vrs_vet and RVT.cod_adm = 1 and RVT.cod_ses = 2 and RVT.cod_tre is not null\n"
				+ "      ) then 2\n"
				+ "      else 1\n"
				+ "    end as cod_ses\n"
				+ "  from ins_adm_etp IAE\n"
				+ "  inner join vet_permet_acc_vet VPV on VPV.cod_etp_prm = IAE.cod_etp and VPV.cod_vrs_vet_prm = IAE.cod_vrs_vet\n"
				+ "  inner join version_etape VET on VET.cod_etp = IAE.cod_etp and VET.cod_vrs_vet = IAE.cod_vrs_vet\n"
				+ "  where IAE.cod_ind = " + cod_ind + "\n"
				+ "    and IAE.eta_iae = 'E'\n"
				+ "    and IAE.eta_pmt_iae = 'P'\n"
				+ "    and exists (\n" // Et qu'il existe un résultat positif à l'étape
				+ "      select null\n"
				+ "      from resultat_vet RVT\n"
				+ "      inner join typ_resultat TRE on TRE.cod_tre = RVT.cod_tre\n"
				+ "      where RVT.cod_ind = IAE.cod_ind and RVT.cod_anu = IAE.cod_anu and RVT.cod_etp = IAE.cod_etp and RVT.cod_vrs_vet = IAE.cod_vrs_vet and RVT.cod_adm = 1 and (TRE.cod_neg_tre = 1 or RVT.cod_tre = 'AJAC')\n"
				+ "    )\n"
				+ "    and not exists (\n" // Et qu'il n'existe pas de résultat positif à l'étape accessible (sans tenir compte de la version ni de l'année)
				+ "      select null\n"
				+ "      from resultat_vet RVT\n"
				+ "      inner join typ_resultat TRE on TRE.cod_tre = RVT.cod_tre\n"
				+ "      where RVT.cod_ind = IAE.cod_ind and RVT.cod_etp = VPV.cod_etp and RVT.cod_adm = 1 and TRE.cod_neg_tre = 1\n"
				+ "    )\n"
				+ ") presel\n"
				// Jointures
				+ "left join individu IND on IND.cod_ind = presel.cod_ind\n"
				+ "left join etape ETP on ETP.cod_etp = presel.cod_etp\n"
				+ "left join version_etape VET on VET.cod_etp = presel.cod_etp and VET.cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "left join vdi_fractionner_vet VDE on VDE.cod_etp = presel.cod_etp and VDE.cod_vrs_vet = presel.cod_vrs_vet\n"
				+ "left join diplome DIP on DIP.cod_dip = VDE.cod_dip\n"
				+ "left join ind_sanctionne_blo IBL on IBL.cod_ind = presel.cod_ind\n"
				+ "  and exists (\n"
				+ "    select null\n"
				+ "    from blocage\n"
				+ "    where cod_blo = IBL.cod_blo\n"
				+ "      and cod_tpb in ('A', 'T')\n"
				+ "  )\n"
				+ "  and (IBL.cod_etp is null or IBL.cod_etp = presel.cod_etp)\n"
				+ "  and (IBL.dat_deb_blo is null or TO_DATE(TO_CHAR(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') >= IBL.dat_deb_blo)\n"
				+ "  and (IBL.dat_fin_blo is null or TO_DATE(TO_CHAR(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') <= IBL.dat_fin_blo)\n"
				+ "left join blocage BLO on BLO.cod_blo = IBL.cod_blo\n"
				+ "where (select cod_anu from annee_uni where eta_anu_iae = 'O') between VDE.daa_deb_rct_vet and VDE.daa_fin_val_vet\n"
				+ "order by presel.cod_etp, presel.cod_vrs_vet";

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, false);
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
		}
%>
		<h2>Activité IPWEB</h2>
<%
			query =
				  "select AST.dat_operation, AST.lib_operation, AST.cod_etp, AST.cod_vrs_vet, VET.lib_web_vet\n"
				+ "from adip_statistique AST\n"
				+ "left join version_etape VET on VET.cod_etp = AST.cod_etp and VET.cod_vrs_vet = AST.cod_vrs_vet\n"
				+ "where AST.cod_ind = " + cod_ind + "\n"
				+ "  and AST.cod_anu = (select cod_anu from annee_uni where eta_anu_iae = 'O')\n"
				+ "order by AST.dat_operation";

			try {
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, false);
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
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
