<%--
 * functions.jsp - Fonctions utilitaires génériques
 *
 * Copyright (C) 2013 Université Paris 1 Panthéon-Sorbonne
 *
 * Auteurs :
 *  VRI   Vincent Rivière
 *
 * Ce fichier est distribué sous licence GPLv3.
 * Voir le fichier license.txt pour les détails.
--%>
<%@ page pageEncoding="utf-8" %>
<%@ page import="javax.naming.*" %>
<%@ page import="javax.sql.*" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.text.*" %>
<%@ page import="edu.yale.its.tp.cas.client.filter.*" %>
<%!
private static class UrlBuilder {
	private String baseUrl;
	private Map parameters;
	
	public UrlBuilder(String url) {
		initialize(url);
	}
	
	public void initialize(String url) {
		parameters = new LinkedHashMap();
		
		int posQuery = url.indexOf('?');
		if (posQuery == -1) {
			baseUrl = url;
			return;
		}

		baseUrl = url.substring(0, posQuery);
		
		int pos = posQuery + 1;
		while (pos < url.length()) {
			int pairEnd = url.indexOf('&', pos);
			if (pairEnd == -1)
				pairEnd = url.length();
			
			int posParamName = pos;
			int posParamNameEnd = url.indexOf('=', posParamName);
			if (posParamNameEnd == -1 || posParamNameEnd > pairEnd)
				posParamNameEnd = pairEnd;
			String paramName = url.substring(posParamName, posParamNameEnd);
			pos = posParamNameEnd + 1;

			String paramValue = null;
			if (pos < pairEnd) {
				int posParamValue = pos;
				int posParamValueEnd = url.indexOf('&', posParamValue);
				if (posParamValueEnd == -1)
					posParamValueEnd = url.length();
				paramValue = url.substring(posParamValue, posParamValueEnd);
				pos = posParamValueEnd + 1;
			}

			// TODO urlDecode ?

			//System.out.println("DBG: " + paramName + '|' + paramValue);
			parameters.put(paramName, paramValue);
		}
	}

	public String toString() {
		StringBuffer sb = new StringBuffer(baseUrl);
		
		if (!parameters.isEmpty()) {
			sb.append('?');
			
			Set names = parameters.keySet();
			for (Iterator it = names.iterator(); it.hasNext(); ) {
				String name = (String)it.next();
				String value = (String)parameters.get(name);
				
				sb.append(name);

				if (value != null)
					sb.append('=').append(value);
				
				if (it.hasNext())
					sb.append('&');
			}
		}
		
		return sb.toString();
	}
	
	public boolean hasParameter(String name) {
		return parameters.containsKey(name);
	}
	
	public String getParameter(String name) {
		String value = (String)parameters.get(name);
		// TODO urlDecode
		return value;
	}
	
	public void setParameter(String name, String value) {
		value = urlEncode(value);
		parameters.put(name, value);
	}
	
	public void removeParameter(String name) {
		parameters.remove(name);
	}
}

private static class AccessDeniedException extends RuntimeException {
	public AccessDeniedException(String message) {
		super(message);
	}

	public AccessDeniedException(String message, Throwable cause) {
		super(message, cause);
	}
}

private static String htmlEncodeGeneric(String str, boolean inQuotes) {
	if (str == null)
		return null;

	StringBuffer sb = new StringBuffer();

	for (int i = 0; i < str.length(); ++i) {
		char ch = str.charAt(i);

		if (ch == '<') {
			sb.append("&lt;");
		}
		else if (ch == '>') {
			sb.append("&gt;");
		}
		else if (ch == '&') {
			sb.append("&amp;");
		}
		else if (inQuotes && ch == '"') {
			sb.append("&quot;");
		}
		else {
			sb.append(ch);
		}
	}

	return sb.toString();
}

private static String htmlEncode(String str) {
	return htmlEncodeGeneric(str, false);
}

private static String htmlEncodeInQuotes(String str) {
	return htmlEncodeGeneric(str, true);
}

private static String urlEncode(String str) {
	byte[] bytes;
	try {
		bytes = str.getBytes("UTF-8");
	}
	catch (UnsupportedEncodingException e) {
		throw new RuntimeException("Unsupported encoding", e);
	}

	StringBuffer sb = new StringBuffer();

	for (int i = 0; i < bytes.length; ++i) {
		char ch = (char)(bytes[i] & 0xff); // Convert unsigned byte to char

		if (ch == ' ') {
			sb.append('+');
		}
		else if (ch < ' ' || ch > '~' || ":/?=&#%+".indexOf(ch) >= 0) {
			int code = (int)ch;
			sb.append('%');
			sb.append(Integer.toHexString(0x100 | code).substring(1).toUpperCase());
		}
		else {
			sb.append(ch);
		}
	}

	return sb.toString();
}

private static String sqlEncodeInQuotes(String str) {
	StringBuffer sb = new StringBuffer();

	for (int i = 0; i < str.length(); ++i) {
		char ch = str.charAt(i);

		if (ch == '\'') {
			sb.append("''");
		}
		else {
			sb.append(ch);
		}
	}

	return sb.toString();
}

private static String jsEncodeInSingleQuotes(String str) {
	StringBuffer sb = new StringBuffer();

	for (int i = 0; i < str.length(); ++i) {
		char ch = str.charAt(i);

		if (ch == '\'') {
			sb.append("\\'");
		}
		else if (ch == '\\') {
			sb.append("\\\\");
		}
		else if (ch == '\n') {
			sb.append("\\n");
		}
		else if (ch == '\r') {
			sb.append("\\r");
		}
		else if (ch == '\t') {
			sb.append("\\t");
		}
		else if (ch == '\b') {
			sb.append("\\b");
		}
		else if (ch == '\f') {
			sb.append("\\f");
		}
		else {
			sb.append(ch);
		}
	}

	return sb.toString();
}

private static String htmlStringNull(String str) {
	if (str == null)
		return "(null)";
	else
		return htmlEncode(str);
}

private static String htmlStringMaybeEmpty(String str) {
	if (str == null)
		return "";
	else
		return htmlEncode(str);
}

private static String htmlStringMaybeEmptyInQuotes(String str) {
	if (str == null)
		return "";
	else
		return htmlEncodeInQuotes(str);
}

private static void printTdStartTag(JspWriter out, List cssClasses) throws IOException {
	out.print("<td");

	boolean atLeastOneClass = false;
	for (Iterator iter = cssClasses.iterator(); iter.hasNext(); ) {
		String cssClass = (String)iter.next();
		
		if (!atLeastOneClass) {
			out.print(" class=\"" + cssClass);
			atLeastOneClass = true;
		}
		else {
			out.print(" " + cssClass);
		}
	}
	
	if (atLeastOneClass)
		out.print("\"");
		
	out.print(">");
}

private static void printStandardTdTag(JspWriter out, String value, boolean nullIsFailure) throws IOException {
	List cssClasses = new ArrayList();

	if (value == null) {
		cssClasses.add("null");
		
		if (nullIsFailure)
			cssClasses.add("failure");
	}

	printTdStartTag(out, cssClasses);
	out.print(htmlStringNull(value));
	out.print("</td>");
}

private interface HtmlTableRenderer {
	public void beforeRenderRow(ResultSet rs) throws SQLException;
	public void renderCell(JspWriter out, ResultSet rs, int column) throws IOException, SQLException;
	public void renderCellContent(JspWriter out, ResultSet rs, int column, String value) throws IOException, SQLException;
	public DateFormat getDateFormat(int column);
}

private static class StandardHtmlTableRenderer implements HtmlTableRenderer {
	private boolean nullIsFailure;
	private static final DateFormat defaultDateFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm:ss");

	public StandardHtmlTableRenderer(boolean nullIsFailure) {
		this.nullIsFailure = nullIsFailure;
	}

	protected String getTextValue(ResultSet rs, int column) throws SQLException {
		ResultSetMetaData rsmd = rs.getMetaData();
		String sqlType = rsmd.getColumnTypeName(column);
		
		if (sqlType.equals("DATE")) {
			java.sql.Timestamp value = rs.getTimestamp(column);
			return value == null ? null : getDateFormat(column).format(value);
		}
		else if (sqlType.equals("NUMBER")) {
			String value = rs.getString(column);
			if (value == null)
				return null;

			if (value.length() >= 1 && value.charAt(0) == '.') // .123 sans zéro devant
				value = "0" + value;

			return value;
		}
		else {
			return rs.getString(column);
		}
	}

	public void beforeRenderRow(ResultSet rs) throws SQLException {
	
	}

	public void renderCell(JspWriter out, ResultSet rs, int column) throws IOException, SQLException {
		String value = getTextValue(rs, column);
		printTdStartTag(out, getCssClasses(rs, column, value));
		renderCellContent(out, rs, column, value);
		out.println("</td>");
	}

	public void renderCellContent(JspWriter out, ResultSet rs, int column, String value) throws IOException, SQLException {
		out.print(htmlStringNull(value));
	}

	public DateFormat getDateFormat(int column) {
		return defaultDateFormat;
	}

	public boolean getNullIsFailure(int column) {
		return nullIsFailure;
	}
	
	public void addAdditionalCssClasses(List cssClasses, ResultSet rs, int column, String value) throws SQLException {
		if (value == null && getNullIsFailure(column))
			cssClasses.add("failure");
	}

	private List getCssClasses(ResultSet rs, int column, String value) throws SQLException {
		List cssClasses = new ArrayList();

		if (value == null) {
			cssClasses.add("null");
		}

		ResultSetMetaData rsmd = rs.getMetaData();
		String sqlType = rsmd.getColumnTypeName(column);
		if (sqlType.equals("NUMBER")) {
			cssClasses.add("right");
		}

		addAdditionalCssClasses(cssClasses, rs, column, value);

		return cssClasses;
	}
}

private static int printResultSet(JspWriter out, ResultSet rs, HtmlTableRenderer renderer, int limit, String sortUrl) throws IOException, SQLException {
	UrlBuilder targetUrlBuilder = null;
	int currentAscColumn = 0;

	if (sortUrl != null) {
		targetUrlBuilder = new UrlBuilder(sortUrl);

		String strOrder = targetUrlBuilder.getParameter("order");
		if (strOrder != null) {
			String strDir = targetUrlBuilder.getParameter("dir");
			if (!(strDir != null && strDir.equals("desc")))
				currentAscColumn = Integer.parseInt(strOrder);
		}
	}

	ResultSetMetaData rsmd = rs.getMetaData();

	out.println("<table class=\"resultset\">");

	// Header
	out.println("<tr>");
	for (int column = 1; column <= rsmd.getColumnCount(); ++column) {
		String header = rsmd.getColumnName(column);
		String targetUrl = null;
		
		if (targetUrlBuilder != null) {
			targetUrlBuilder.setParameter("order", String.valueOf(column));

			if (column == currentAscColumn)
				targetUrlBuilder.setParameter("dir", "desc");
			else
				targetUrlBuilder.removeParameter("dir");

			targetUrl = targetUrlBuilder.toString();
		}

		if (targetUrl != null) {
			out.println("<th><a href=\"" + htmlEncodeInQuotes(targetUrl) + "\">" + htmlEncode(header) + "</a></th>");
		}
		else {
			out.println("<th>" + htmlEncode(header) + "</th>");
		}
	}
	out.println("</tr>");

	// Data
    int count = 0;
	while (rs.next() && (limit < 0 || count < limit)) {
		renderer.beforeRenderRow(rs);

		out.println("<tr onclick=\"toggleSelect(this)\">");
		for (int column = 1; column <= rsmd.getColumnCount(); ++column) {
			renderer.renderCell(out, rs, column);
		}
		out.println("</tr>");

        ++count;
	}

	out.println("</table>");

    return count;
}

private static int printResultSet(JspWriter out, ResultSet rs, HtmlTableRenderer renderer, int limit) throws IOException, SQLException {
	return printResultSet(out, rs, renderer, limit, null);
}

private static int printResultSet(JspWriter out, ResultSet rs, HtmlTableRenderer renderer) throws IOException, SQLException {
	return printResultSet(out, rs, renderer, -1);
}

private static int printResultSet(JspWriter out, ResultSet rs, boolean nullIsFailure) throws IOException, SQLException {
	return printResultSet(out, rs, new StandardHtmlTableRenderer(nullIsFailure));
}

private static int printResultSet(JspWriter out, ResultSet rs, boolean nullIsFailure, String sortUrl) throws IOException, SQLException {
	return printResultSet(out, rs, new StandardHtmlTableRenderer(nullIsFailure), -1, sortUrl);
}

private static int printResultSet(JspWriter out, ResultSet rs, boolean nullIsFailure, int limit) throws IOException, SQLException {
	return printResultSet(out, rs, new StandardHtmlTableRenderer(nullIsFailure), limit);
}

private static void printResultSet(JspWriter out, ResultSet rs) throws IOException, SQLException {
	printResultSet(out, rs, false);
}

private static void printQuery(JspWriter out, String query) throws IOException {
	out.print("<pre class=\"query\">");
	out.println(htmlEncode(query));
	out.println("</pre>");
}

private static void printSQLException(JspWriter out, SQLException e, String query) throws IOException {
	out.println("<table class=\"error\">");

	out.println("<tr><td><pre class=\"errordescription\">" + htmlEncode(e.getMessage()) + "</pre></td></tr>");

	out.println("<tr><td>");
	printQuery(out, query);
	out.println("</td></tr>");

	out.println("</table>");
}

private static class QueryException extends Exception {
	private String query;
	private SQLException sqlException;
	
	public QueryException(String query, SQLException sqlException) {
		this.query = query;
		this.sqlException = sqlException;
	}
	
	public SQLException getSQLException() {
		return sqlException;
	}

	public Throwable getCause() {
		return getSQLException();
	}

	public String getMessage() {
		return getSQLException().getMessage();
	}

	public String getQuery() {
		return query;
	}
}

private static int executeUpdateQuery(Connection con, String query) throws QueryException {
	try {
		Statement stmt = con.createStatement();
		try {
			return stmt.executeUpdate(query);
		}
		finally {
			stmt.close();
		}
	}
	catch (SQLException e) {
		throw new QueryException(query, e);
	}
}

private static boolean executeExistsQuery(Connection con, String query) throws QueryException {
	try {
		Statement stmt = con.createStatement();
		try {
			ResultSet rs = stmt.executeQuery(query);
			return rs.next();
		}
		finally {
			stmt.close();
		}
	}
	catch (SQLException e) {
		throw new QueryException(query, e);
	}
}

private static String executeStringQuery(Connection con, String query) throws QueryException {
	try {
		Statement stmt = con.createStatement();
		try {
			ResultSet rs = stmt.executeQuery(query);
			rs.next();
			return rs.getString(1);
		}
		finally {
			stmt.close();
		}
	}
	catch (SQLException e) {
		throw new QueryException(query, e);
	}
}

private static int getSequenceNextVal(Connection con, String sequence) throws QueryException {
	String query =
		"select " + sequence + ".nextval\n"
	  + "from dual";

	try {
		Statement stmt = con.createStatement();
		try {
			ResultSet rs = stmt.executeQuery(query);
			rs.next();

			return rs.getInt(1);
		}
		finally {
			stmt.close();
		}
	}
	catch (SQLException e) {
		throw new QueryException(query, e);
	}
}

private static void printQueryException(JspWriter out, QueryException e) throws IOException {
	printSQLException(out, e.getSQLException(), e.getQuery());
}

private static String getPageName(HttpServletRequest request) {
	String uri = request.getRequestURI();
	return uri.substring(uri.lastIndexOf('/') + 1);
}

private static String getPageNameWithQuery(HttpServletRequest request) {
	String page = getPageName(request);

	String query = request.getQueryString();
	if (query == null)
		return page;
	else
		return page + "?" + query;
}

private static String getReferrerWithoutQuery(HttpServletRequest request) {
	String referrer = request.getHeader("Referer");
	if (referrer == null)
		return null;

	int posQuery = referrer.indexOf('?') ;
	if (posQuery < 0)
		return referrer;

	return referrer.substring(0, posQuery);
}

private static String getFullUrl(HttpServletRequest request) {
	String page = request.getScheme() + "://" + request.getHeader("Host") + request.getRequestURI().toString();

	String query = request.getQueryString();
	if (query == null)
		return page;
	else
		return page + "?" + query;
}

private static boolean isPostToSelf(HttpServletRequest request) {
	if (!request.getMethod().equals("POST")) {
		return false;
	}

	String referrer = getReferrerWithoutQuery(request);
	if (referrer == null || !referrer.equals(request.getRequestURL().toString())) {
		return false;
	}
	
	return true;
}

private static String getStringAttribute(ServletRequest request, String name, String defaultValue) {
	String attribute = (String)request.getAttribute(name);
	return attribute != null ? attribute : defaultValue;
}

private static boolean getBooleanAttribute(ServletRequest request, String name, boolean defaultValue) {
	Boolean attribute = (Boolean)request.getAttribute(name);
	return attribute != null ? attribute.booleanValue() : defaultValue;
}

boolean removeTicketParameter(HttpServletRequest request, HttpServletResponse response) throws IOException {
	if (!request.getMethod().equals("GET"))
		return false;

	if (request.getParameter("ticket") == null)
		return false;

	UrlBuilder ub = new UrlBuilder(getPageNameWithQuery(request));
	ub.removeParameter("ticket");
	response.sendRedirect(ub.toString());

	return true;
}

private static Connection getOracleConnection(String host, int port, String login, String password, String sid) throws Exception {
	Class.forName("oracle.jdbc.driver.OracleDriver");
	String url = "jdbc:oracle:thin:@" + host + ":" + port + ":" + sid;
	return DriverManager.getConnection(url, login, password);
}

private static String getDatabaseName(Connection con) throws SQLException {
	String query =
		   "select sys_context('USERENV', 'DB_NAME')\n"
		 + "from dual";

	Statement stmt = con.createStatement();
	try {
		ResultSet rs = stmt.executeQuery(query);
		rs.next();
		return rs.getString(1);
	}
	finally {
		stmt.close();
	}
}

private static String getUserName(Connection con) throws SQLException {
	String query =
		   "select user\n"
		 + "from dual";

	Statement stmt = con.createStatement();
	try {
		ResultSet rs = stmt.executeQuery(query);
		rs.next();
		return rs.getString(1);
	}
	finally {
		stmt.close();
	}
}

private static String getLoginCas(HttpServletRequest request) {
	HttpSession session = request.getSession();
	return (String)session.getAttribute(CASFilter.CAS_FILTER_USER);
}

private static char generateRandomChar(boolean upper, boolean lower, boolean digit) {
	StringBuffer sb = new StringBuffer();
	
	if (upper) {
		for (int i = (int)'A'; i <= (int)'Z'; i++) {
			sb.append((char)i);
		}
	}
	
	if (lower) {
		for (int i = (int)'a'; i <= (int)'z'; i++) {
			sb.append((char)i);
		}
	}
	
	if (digit) {
		for (int i = (int)'0'; i <= (int)'9'; i++) {
			sb.append((char)i);
		}
	}

	int i = (int)(Math.random() * sb.length());
	return sb.charAt(i);
}

private static String generateOraclePassword() {
	StringBuffer sb = new StringBuffer(29);

	// Le premier caractère doit être une lettre
	sb.append(generateRandomChar(true, true, false));
	
	// Les caractères suivants peuvent être des lettres ou des chiffres
	for (int i = 1; i < 29; i++) {
		sb.append(generateRandomChar(true, true, true));
	}

	return sb.toString();
}

private static void syncGroupeGrouper(String groupe) throws MalformedURLException, IOException {
	URL url = new URL("https://grouper.univ-paris1.fr/sync-grouper-loader-group-and-export-to-LDAP.cgi?" + groupe);
	InputStream stream = url.openStream();
	try {
		while (stream.read() != -1) {
			// Nothing
		}
	}
	finally {
		stream.close();
	}
}
%>
