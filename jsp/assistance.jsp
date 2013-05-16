<%--
 * assistance.jsp - Assistance étudiants
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
private static class MyRenderer extends StandardHtmlTableRenderer {
	private String config;
	private boolean opi;
	private static final DateFormat dayDateFormat = new SimpleDateFormat("dd/MM/yyyy");

	public MyRenderer(String config, boolean opi) {
		super(true);
		this.config = config;
		this.opi = opi;
	}

	public void renderCellContent(JspWriter out, ResultSet rs, int column, String value) throws IOException, SQLException {
		super.renderCellContent(out, rs, column, value);
		
		if (column == 1) {
			if (opi) {
				String cod_opi_int_epo = rs.getString(column);
				out.print(" <a href=\"detail_opi.jsp?config=" + htmlEncode(urlEncode(config)) + "&amp;cod_opi_int_epo=" + htmlEncodeInQuotes(urlEncode(cod_opi_int_epo)) + "\"><img src=\"detail.gif\" width=\"14\" height=\"14\" alt=\"Détail\" title=\"Détail\" border=\"0\"></a>");
			}
			else {
				int cod_etu = rs.getInt(column);
				out.print(" <a href=\"detail_etudiant.jsp?config=" + htmlEncode(urlEncode(config)) + "&amp;cod_etu=" + cod_etu + "\"><img src=\"detail.gif\" width=\"14\" height=\"14\" alt=\"Détail\" title=\"Détail\" border=\"0\"></a>");
			}
		}
	}

	public DateFormat getDateFormat(int column) {
		if (column == 4) {
			return dayDateFormat;
		}
		else {
			return super.getDateFormat(column);
		}
	}
}
%>
<%
	if (removeTicketParameter(request, response))
		return;

	Properties properties = getApplicationProperties();
	Connection con = getConnection(properties, request);
	try {
		String pageTitle = getApplicationPageTitle(properties, con, "Assistance pour inscriptions");
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <title><%= htmlEncode(pageTitle)%></title>
		<link rel="stylesheet" type="text/css" href="styles.css">
		<script type="text/javascript" src="scripts.js"></script>
    </head>
    <body>
        <h1><%= htmlEncode(pageTitle)%></h1>
		<p class="description">
			Cette page permet de rechercher un étudiant dans Apogée pour aider à la résolution des problèmes d'inscriptions.
		</p>
<%
		String config2 = getConfig(properties, request);

		String filtre = request.getParameter("filtre");
		if (filtre == null)
			filtre = "";
		filtre = filtre.trim();
%>
		<div style="background-color: #ffdddd; padding: 0.5em; margin-top: 0em; margin-bottom: 1em">
			Veuillez saisir un code étudiant, code candidat APB, code candidat Sésame, ou nom de famille.
			<form name="recherche" method="GET" action="<%= htmlEncodeInQuotes(getPageName(request)) %>">
				<input type="hidden" name="config" value="<%= urlEncode(config2) %>">
				<input type="text" name="filtre" value="<%= htmlEncodeInQuotes(filtre) %>" onclick="select()">
				<input type="submit" value="Rechercher">
			</form>
			<script type="text/javascript">
			//document.recherche.filtre.focus();
			document.recherche.filtre.select();
			</script>
		</div>
<%
		if (!filtre.equals("")) {
%>
		Pour accéder aux détails, veuillez cliquer sur la loupe.
<%
			int intFilter;
			boolean filterIsInt;
			try {
				intFilter = Integer.parseInt(filtre);
				filterIsInt = true;
			}
			catch (NumberFormatException ex) {
				intFilter = 0;
				filterIsInt = false;
			}

			String constraint;
			String query;
			Statement stmt;
			ResultSet rs;
%>
		<h2>Résultats étudiants Apogée</h2>
<%
			constraint = "(1 = 0\n";

			if (filterIsInt) {
				constraint += " or IND.cod_etu = " + intFilter + "\n";
			}

			constraint += " or UPPER(IND.lib_nom_pat_ind) = UPPER('" + sqlEncodeInQuotes(filtre) + "')\n";

			constraint += ")";

			query =
				  "select IND.cod_etu, IND.lib_nom_pat_ind, IND.lib_pr1_ind, IND.date_nai_ind\n"
				+ "from individu IND\n"
				+ "where " + constraint + "\n"
				+ "order by IND.lib_nom_pat_ind, IND.lib_pr1_ind, IND.date_nai_ind, IND.cod_etu";

			try {
				stmt = con.createStatement();
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, new MyRenderer(config2, false));
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
%>
		<h2>Résultats OPI</h2>
<%
			constraint = "(1 = 0\n";
			constraint += " or UPPER(OPI.cod_opi_int_epo) = UPPER('" + sqlEncodeInQuotes(filtre) + "')\n";
			constraint += " or UPPER(OPI.cod_opi_int_epo) = 'PB12' || UPPER('" + sqlEncodeInQuotes(filtre) + "')\n";
			constraint += " or UPPER(OPI.cod_opi_int_epo) = 'PB120' || UPPER('" + sqlEncodeInQuotes(filtre) + "')\n";
			constraint += " or UPPER(OPI.cod_opi_int_epo) = 'PB1200' || UPPER('" + sqlEncodeInQuotes(filtre) + "')\n";
			constraint += " or UPPER(OPI.lib_nom_pat_ind_opi) = UPPER('" + sqlEncodeInQuotes(filtre) + "')\n";
			constraint += ")";

			query =
				  "select OPI.cod_opi_int_epo, OPI.lib_nom_pat_ind_opi, OPI.lib_pr1_ind_opi, OPI.date_nai_ind_opi/*, OPI.cod_pop_up1*/\n"
				+ "from ind_opi OPI\n"
				+ "where " + constraint + "\n"
				+ "order by OPI.cod_opi_int_epo, OPI.lib_nom_pat_ind_opi, OPI.lib_pr1_ind_opi, OPI.date_nai_ind_opi";

			try {
				stmt = con.createStatement();
				rs = stmt.executeQuery(query);
				printResultSet(out, rs, new MyRenderer(config2, true));
			}
			catch (SQLException e) {
				printSQLException(out, e, query);
			}
		}
	}
	finally {
		con.close();
	}
%>
	</body>
</html>
