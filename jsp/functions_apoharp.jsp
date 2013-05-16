<%--
 * functions_apoharp.jsp - Fonctions utilitaires spécifiques Apogée/Harpège
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
<%@ page import="java.util.*" %>
<%@ page import="javax.sql.*" %>
<%@ page import="javax.naming.*" %>
<%@ page import="javax.naming.directory.*" %>
<%@ page import="java.security.*" %>
<%!
private static Properties getApplicationProperties() throws IOException {
	Properties properties = new Properties();
	ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
	properties.load(classLoader.getResourceAsStream("utilitaires/application.properties"));
	return properties;
}

private static String getApplicationName(Properties properties) {
	String application = properties.getProperty("application.name");
	if (application.equals("apogee"))
		application = "Apogée";
	else if (application.equals("harpege"))
		application = "Harpège";

	return application;
}

private static String getApplicationPageTitle(Properties properties, Connection con, String title) throws SQLException {
	String application = getApplicationName(properties);
	String databaseName = getDatabaseName(con);
	return application + " - " + title + " (" + databaseName + ")";
}

private static List getConfigurationsActivables(Properties properties) {
	List list = new ArrayList();

	int nbConfigs = Integer.parseInt(properties.getProperty("config.nb"));
	for (int i = 0; i < nbConfigs; ++i) {
		String nom = properties.getProperty("config." + i + ".nom");
		list.add(nom);
	}

	return list;
}

private static String getConfig(Properties properties, HttpServletRequest request) {
	String config = request.getParameter("config");
	if (config == null) {
		List configList = getConfigurationsActivables(properties);
		config = (String)configList.get(0);
	}

	return config;
}

private static Connection getConnection(Properties properties, String login, String password, String sid) throws Exception {
	String host = properties.getProperty("db.host");
	int port = Integer.parseInt(properties.getProperty("db.port"));
	return getOracleConnection(host, port, login, password, sid);
}

private static DirContext getRootContextOid(Properties properties) throws IOException, NamingException {
	String serverIP = properties.getProperty("oid.host");
	String port = properties.getProperty("oid.port");
	String bindDn = properties.getProperty("oid.bindn");
	String password = properties.getProperty("oid.password");

	Hashtable environment = new Hashtable();
	environment.put("java.naming.factory.initial", "com.sun.jndi.ldap.LdapCtxFactory");
	environment.put("java.naming.provider.url", "ldap://" + serverIP + ":" + port);
	environment.put("java.naming.security.authentication", "simple");
	environment.put("java.naming.security.principal", bindDn);
	environment.put("java.naming.security.credentials", password);
	DirContext rootContext = new InitialDirContext(environment);
	return rootContext;
}

private static String getDnOracleUser(DirContext rootContextOid, String loginCas) throws NamingException {
	String name = "cn=Users,dc=univ-paris1,dc=fr";
	String filter = "(uid=" + ldapFilterEncode(loginCas) + ")";
	return getLdapDn(rootContextOid, name, SearchControls.ONELEVEL_SCOPE, filter);
}

private static Attributes getAttributesOracleUser(DirContext rootContextOid, String loginCas, String[] attrs) throws NamingException {
	String name = "cn=Users,dc=univ-paris1,dc=fr";
	String filter = "(uid=" + ldapFilterEncode(loginCas) + ")";
	return getLdapAttributes(rootContextOid, name, SearchControls.ONELEVEL_SCOPE, filter, attrs);
}

private static String getUserGuid(DirContext rootContextOid, String loginCas) throws NamingException {
	Attributes attributes = getAttributesOracleUser(rootContextOid, loginCas, new String[] { "orclguid" });
	if (attributes == null)
		return null;

	return getAttributeValue(attributes, "orclguid");
}

private static Attributes getAttributesOracleResource(DirContext rootContextOid, String userGuid, String config, String[] attrs) throws NamingException, NameNotFoundException {
	String name = "orclresourcename=" + ldapDnEncode(config) + "+orclresourcetypename=OracleDB,cn=Resource Access Descriptor,orclownerguid=" + ldapDnEncode(userGuid) + ",cn=Extended Properties,cn=OracleContext,dc=univ-paris1,dc=fr";
	String filter = "(objectClass=orclresourcedescriptor)";
	return getLdapAttributes(rootContextOid, name, SearchControls.OBJECT_SCOPE, filter, attrs);
}

private static String getLoginOracle(Properties properties, String loginCas, String config) throws Exception {
	DirContext rootContextOid = getRootContextOid(properties);
	try {
		String userGuid = getUserGuid(rootContextOid, loginCas);
		if (userGuid == null)
			return null;

		Attributes resourceAttributes = getAttributesOracleResource(rootContextOid, userGuid, config, new String[] { "orcluseridattribute" });
		if (resourceAttributes == null)
			return null;

		return getAttributeValue(resourceAttributes, "orcluseridattribute");
	}
	finally {
		rootContextOid.close();
	}
}

private static Connection getConnection(Properties properties, String loginCas, String config) throws Exception {
	DirContext rootContextOid = getRootContextOid(properties);
	try {
		try {
			String userGuid = getUserGuid(rootContextOid, loginCas);
			if (userGuid == null) {
				throw new AccessDeniedException("Accès refusé.");
			}

			Attributes resourceAttributes = getAttributesOracleResource(rootContextOid, userGuid, config, new String[] { "orcluseridattribute", "orclpasswordattribute", "orclflexattribute1" });
			String userOracle = getAttributeValue(resourceAttributes, "orcluseridattribute");
			String passwordOracle = getAttributeValue(resourceAttributes, "orclpasswordattribute");
			String sid = getAttributeValue(resourceAttributes, "orclflexattribute1");

			return getConnection(properties, userOracle, passwordOracle, sid);
		}
		catch (NameNotFoundException e) {
			throw new AccessDeniedException("Accès refusé à la configuration " + config + ".", e);
		}
	}
	finally {
		rootContextOid.close();
	}
}

private static Connection getConnection(Properties properties, HttpServletRequest request) throws Exception {
	String loginCas = getLoginCas(request);
	String config = getConfig(properties, request);
	return getConnection(properties, loginCas, config);
}

private static Connection getConnection(HttpServletRequest request) throws Exception {
	Properties properties = getApplicationProperties();
	return getConnection(properties, request);
}

private static boolean isUserOfConfig(DirContext rootContextOid, String userGuid, String config) throws NamingException {
	try {
		String name = "orclresourcename=" + ldapDnEncode(config) + "+orclresourcetypename=OracleDB,cn=Resource Access Descriptor,orclownerguid=" + ldapDnEncode(userGuid) + ",cn=Extended Properties,cn=OracleContext,dc=univ-paris1,dc=fr";
		String filter = "(objectClass=orclresourcedescriptor)";
		String[] attrs = new String[0]; // No attributes
		getLdapAttributes(rootContextOid, name, SearchControls.OBJECT_SCOPE, filter, attrs);
	}
	catch (NameNotFoundException e) {
		return false;
	}

	return true;
}

// Récupère le login Oracle et le mot de passe pour une configuration donnée
private static boolean getUserAndPass(DirContext rootContextOid, String userGuid, String config, String[] ret) throws NamingException {
	try {
		Attributes resourceAttributes = getAttributesOracleResource(rootContextOid, userGuid, config, new String[]{"orcluseridattribute", "orclpasswordattribute"});
		ret[0] = getAttributeValue(resourceAttributes, "orcluseridattribute"); // User Oracle
		ret[1] = getAttributeValue(resourceAttributes, "orclpasswordattribute"); // Password Oracle
		return true;
	}
	catch (NameNotFoundException e) {
		return false;
	}
}

// Récupère le login Oracle et le mot de passe pour la première configuration trouvée
private static boolean guessUserAndPass(Properties properties, DirContext rootContextOid, String userGuid, String[] ret) throws NamingException {
	List configList = getConfigurationsActivables(properties);
	for (Iterator it = configList.iterator(); it.hasNext(); ) {
		String configName = (String)it.next();

		// Ignorer les configurations non standard
		if (configName.endsWith("2") || configName.endsWith("3"))
			continue;

		if (getUserAndPass(rootContextOid, userGuid, configName, ret))
			return true;
	}
	
	return false;
}
	
private static boolean existeUserOracle(Connection con, String user) throws QueryException {
	user = user.toUpperCase();

	return executeExistsQuery(con,
		"select null\n"
	  + "from all_users\n"
	  + "where username = '" + sqlEncodeInQuotes(user) + "'"
	);
}

private static void creerUserOracle(Connection con, String user, String password) throws QueryException {
	executeUpdateQuery(con,
		"create user " + user + "\n"
	  + "identified by " + password + "\n"
	  + "default tablespace data_apo\n"
	  + "temporary tablespace temporary"
	);

	executeUpdateQuery(con, "grant role_apogee_read, role_apogee_report, role_apogee_write to " + user);

	executeUpdateQuery(con, "alter user " + user + " default role role_apogee_read");

	// Chaque utilisateur doit avoir le droit execute sur les packages APOGEE
	executeUpdateQuery(con, "call PKAD.f_grant_pk_uti('" + sqlEncodeInQuotes(user) + "')");
}

private static void changerMotDePasseOracle(Connection con, String user, String password) throws QueryException {
	executeUpdateQuery(con,
		"alter user " + user + "\n"
	  + "identified by " + password
	);
}

private static void deverrouillerCompteOracle(Connection con, String user) throws QueryException {
	executeUpdateQuery(con,
		"alter user " + user + "\n"
	  + "account unlock"
	);
}

private static void supprimerUserOracle(Connection con, String user) throws QueryException {
	user = user.toLowerCase();

	// Safety check
	if (user.equals("sys")
		|| user.equals("sysman")
		|| user.equals("system")
		|| user.equals("dbsnmp")
		|| user.equals("apogee")
		|| user.equals("up1")
		|| user.equals("conv")
		|| user.equals("apo_bo_dico")
		|| user.equals("apo_bo_read")
		|| user.equals("apows")
		|| user.equals("anonymous")
		|| user.equals("admin")
		|| user.equals("web")
		|| user.equals("primo")
		|| user.equals("reins")
		|| user.equals("ipweb")
		|| user.equals("exfsys")
		|| user.equals("graal")
		|| user.equals("scipre")
		|| user.equals("ieweb")
		|| user.equals("mlwrp01") // ???
		|| user.equals("mlwrp02") // ???
		|| user.equals("mlwrp03") // ???
		|| user.equals("mlwrp04") // ???
		|| user.equals("ops$batprod")
		|| user.equals("ops$battest") // ???
		|| user.equals("ops$ora-apogee")
		|| user.equals("oracle_ocm")
		|| user.equals("outln")
		|| user.equals("sexam") // A supprimer définitivement ?
		|| user.equals("wmsys")
		|| user.equals("xdb")
	)
		throw new RuntimeException("Impossible de supprimer l'utilisateur " + user + ".");

	executeUpdateQuery(con, "drop user " + user);
}

private static void creerUserApogee(Connection con, String user) throws QueryException {
	executeUpdateQuery(con,
		"insert into utilisateur (cod_uti, cod_tut, cod_imp, tem_en_sve_uti, cod_num_uti)\n"
	  + "values (UPPER('" + sqlEncodeInQuotes(user) + "'), 'UP1_DE_CONS', 'LOCAL_VISUALISER', 'O', (select max(cod_num_uti) + 1 from utilisateur))"
	);
}

private static void mettreEnServiceUserApogee(Connection con, String user) throws QueryException {
	user = user.toUpperCase();

	executeUpdateQuery(con,
		"update utilisateur\n"
	  + "set tem_en_sve_uti = 'O'\n"
	  + "where cod_uti = '" + sqlEncodeInQuotes(user) + "'"
	);
}

private static void mettreHorsServiceUserApogee(Connection con, String user) throws QueryException {
	user = user.toUpperCase();

	executeUpdateQuery(con,
		"update utilisateur\n"
	  + "set tem_en_sve_uti = 'N'\n"
	  + "where cod_uti = '" + sqlEncodeInQuotes(user) + "'"
	);
}

private static void modifierUserApogee(Connection con, String user, String eMail) throws QueryException {
	user = user.toUpperCase();

	executeUpdateQuery(con,
		"update utilisateur\n"
	  + "set adr_mail_uti = '" + sqlEncodeInQuotes(eMail) + "'\n"
	  + "where cod_uti = '" + sqlEncodeInQuotes(user) + "'"
	);
}

private static void supprimerUserApogee(Connection con, String user) throws QueryException {
	user = user.toUpperCase();

	executeUpdateQuery(con,
		"delete from utilisateur\n"
	  + "where cod_uti = '" + sqlEncodeInQuotes(user) + "'"
	);
}

private static String getApogeeTypeUtilisateur(Connection con, String oracleUser) throws QueryException {
	oracleUser = oracleUser.toUpperCase();

	String query =
		"select tem_en_sve_uti, cod_tut\n"
	  + "from utilisateur\n"
	  + "where cod_uti = '" + sqlEncodeInQuotes(oracleUser) + "'";

	try {
		Statement stmt = con.createStatement();
		try {
			ResultSet rs = stmt.executeQuery(query);
			if (!rs.next())
				throw new AccessDeniedException("Utilisateur inconnu.");

			String enService = rs.getString("TEM_EN_SVE_UTI");
			if (enService == null || !enService.equals("O"))
				throw new AccessDeniedException("Utilisateur désactivé.");

			return rs.getString("COD_TUT");
		}
		finally {
			stmt.close();
		}
	}
	catch (SQLException e) {
		throw new QueryException(query, e);
	}
}

private static boolean isUserApogee(Connection con, String cod_uti) throws QueryException {
	return executeExistsQuery(con,
		"select null\n"
	  + "from utilisateur\n"
	  + "where cod_uti = '" + sqlEncodeInQuotes(cod_uti.toUpperCase()) + "'"
	);
}

private static boolean isUserApogeeEnService(Connection con, String cod_uti) throws QueryException {
	String query =
		  "select tem_en_sve_uti\n"
		+ "from utilisateur\n"
		+ "where cod_uti = '" + sqlEncodeInQuotes(cod_uti.toUpperCase()) + "'";

	try {
		Statement stmt = con.createStatement();
		try {
			ResultSet rs = stmt.executeQuery(query);
			if (!rs.next())
				return false;

			String temEnSve = rs.getString(1);
			return temEnSve != null && temEnSve.equals("O");
		}
		finally {
			stmt.close();
		}
	}
	catch (SQLException e) {
		throw new QueryException(query, e);
	}
}
%>
