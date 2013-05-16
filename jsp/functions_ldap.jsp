<%--
 * functions_ldap.jsp - Fonctions LDAP
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
<%@ page import="javax.naming.directory.*" %>
<%!
private static String ldapFilterEncode(String str) {
	StringBuffer sb = new StringBuffer();

	for (int i = 0; i < str.length(); ++i) {
		char ch = str.charAt(i);

		if (ch < ' ' || ch == 0x007f || "()*\\".indexOf(ch) >= 0) {
			int code = (int)ch;
			sb.append('\\');
			sb.append(Integer.toHexString(0x100 | code).substring(1));
		}
		else {
			sb.append(ch);
		}
	}

	return sb.toString();
}

private static String ldapDnEncode(String str) {
	// Voir RFC 2253
	// Manque encodage des espaces en fin de chaine
	StringBuffer sb = new StringBuffer();

	for (int i = 0; i < str.length(); ++i) {
		char ch = str.charAt(i);

		if ((i == 0 && ch == '#') || ",+\"\\<>;".indexOf(ch) >= 0) {
			sb.append('\\');
			sb.append(ch);
		}
		else if (ch < ' ' || ch == 0x007f) {
			int code = (int)ch;
			sb.append('\\');
			sb.append(Integer.toHexString(0x100 | code).substring(1));
		}
		else {
			sb.append(ch);
		}
	}

	return sb.toString();
}

private static final String LDAP_PARIS1_URL = "ldap://ldap.univ-paris1.fr ldap://fangorn.univ-paris1.fr ldap://ldap2.univ-paris1.fr";

private static DirContext getRootContextParis1() throws NamingException {
	Hashtable environment = new Hashtable();
	environment.put("java.naming.factory.initial", "com.sun.jndi.ldap.LdapCtxFactory");
	environment.put("java.naming.provider.url", LDAP_PARIS1_URL);
	environment.put("java.naming.security.authentication", "simple");
	//environment.put("java.naming.security.principal", "cn=sesame,ou=admin,dc=univ-paris1,dc=fr");
	//environment.put("java.naming.security.credentials", Passwords.sesame);
	DirContext rootContext = new InitialDirContext(environment);
	return rootContext;
}

private static DirContext getRootContextParis1(String userDn, String password) throws NamingException {
	Hashtable environment = new Hashtable();
	environment.put("java.naming.factory.initial", "com.sun.jndi.ldap.LdapCtxFactory");
	environment.put("java.naming.provider.url", LDAP_PARIS1_URL);
	environment.put("java.naming.security.authentication", "simple");
	environment.put("java.naming.security.principal", userDn);
	environment.put("java.naming.security.credentials", password);
	DirContext rootContext = new InitialDirContext(environment);
	return rootContext;
}

private static DirContext getRootContextParis1Test(String userDn, String password) throws NamingException {
	Hashtable environment = new Hashtable();
	environment.put("java.naming.factory.initial", "com.sun.jndi.ldap.LdapCtxFactory");
	environment.put("java.naming.provider.url", "ldap://ldap-test.univ-paris1.fr");
	environment.put("java.naming.security.authentication", "simple");
	environment.put("java.naming.security.principal", userDn);
	environment.put("java.naming.security.credentials", password);
	DirContext rootContext = new InitialDirContext(environment);
	return rootContext;
}

private static String getLdapDn(DirContext context, String name, int scope, String filter) throws NamingException, NameNotFoundException {
	SearchControls cons = new SearchControls();
	cons.setSearchScope(scope);
	cons.setReturningAttributes(new String[0]); // Do not return any attribute

	NamingEnumeration en = context.search(name, filter, cons);
	try {
		if (!en.hasMore())
			return null;

		SearchResult searchResult = (SearchResult)en.next();
		return searchResult.getName() + "," + name;
	}
	finally {
		en.close();
	}
}

private static Attributes getLdapAttributes(DirContext context, String name, int scope, String filter, String[] attrs) throws NamingException, NameNotFoundException {
	SearchControls cons = new SearchControls();
	cons.setSearchScope(scope);
	cons.setReturningAttributes(attrs);

	NamingEnumeration en = context.search(name, filter, cons);
	try {
		if (!en.hasMore())
			return null;

		SearchResult searchResult = (SearchResult)en.next();
		return searchResult.getAttributes();
	}
	finally {
		en.close();
	}
}

private static String getAttributeValue(Attributes attributes, String name) throws NamingException {
	Attribute attribute = attributes.get(name);
	if (attribute == null)
		return null;

	return (String)attribute.get();
}

private static boolean ldapExistsAttributeValue(DirContext rootContextParis1, String name, String attrID, String val) throws NamingException {
	SearchControls ctls = new SearchControls();
	ctls.setSearchScope(SearchControls.OBJECT_SCOPE); // Search object only
	ctls.setReturningAttributes(new String[0]); // Do not return any attribute

	String filter = "(" + ldapFilterEncode(attrID) + "=" + ldapFilterEncode(val) + ")";
	
	NamingEnumeration en = rootContextParis1.search(name, filter, ctls);
	try {
		return en.hasMore();
	}
	finally {
		en.close();
	}
}

private static void ldapAddAttributeValue(DirContext rootContextParis1, String name, String attrID, String val) throws NamingException {
	Attributes attrs = new BasicAttributes();
	attrs.put(attrID, val);
	rootContextParis1.modifyAttributes(name, DirContext.ADD_ATTRIBUTE, attrs);
}

private static void ldapRemoveAttributeValue(DirContext rootContextParis1, String name, String attrID, String val) throws NamingException {
	Attributes attrs = new BasicAttributes();
	attrs.put(attrID, val);
	rootContextParis1.modifyAttributes(name, DirContext.REMOVE_ATTRIBUTE, attrs);
}

private static boolean ldapGroupIsUserMember(DirContext rootContextParis1, String groupName, String userName) throws NamingException {
	String groupDN = "cn=" + ldapDnEncode(groupName) + ",ou=groups,dc=univ-paris1,dc=fr";
	String attrID = "member";
	String value = "uid=" + ldapDnEncode(userName) + ",ou=people,dc=univ-paris1,dc=fr";

	return ldapExistsAttributeValue(rootContextParis1, groupDN, attrID, value);
}

private static void ldapGroupUserAdd(DirContext rootContextParis1, String groupName, String userName) throws NamingException {
	String groupDN = "cn=" + ldapDnEncode(groupName) + ",ou=groups,dc=univ-paris1,dc=fr";
	String attrID = "member";
	String value = "uid=" + ldapDnEncode(userName) + ",ou=people,dc=univ-paris1,dc=fr";

	if (!ldapExistsAttributeValue(rootContextParis1, groupDN, attrID, value))
		ldapAddAttributeValue(rootContextParis1, groupDN, attrID, value);
}

private static void ldapGroupUserRemove(DirContext rootContextParis1, String groupName, String userName) throws NamingException {
	String groupDN = "cn=" + ldapDnEncode(groupName) + ",ou=groups,dc=univ-paris1,dc=fr";
	String attrID = "member";
	String value = "uid=" + ldapDnEncode(userName) + ",ou=people,dc=univ-paris1,dc=fr";

	if (ldapExistsAttributeValue(rootContextParis1, groupDN, attrID, value))
		ldapRemoveAttributeValue(rootContextParis1, groupDN, attrID, value);
}
    
private static String getDnParis1() {
	return "dc=univ-paris1,dc=fr";
}

private static String getDnUsersParis1() {
	return "ou=people," + getDnParis1();
}

private static String getDnUserParis1(String uid) {
	return "uid=" + ldapDnEncode(uid) + "," + getDnUsersParis1();
}

private static Attributes getAttributesUserParis1(DirContext rootContextParis1, String uid, String[] attrs) throws NamingException {
	String name = getDnUsersParis1();
	String filter = "(uid=" + ldapFilterEncode(uid) + ")";
	return getLdapAttributes(rootContextParis1, name, SearchControls.ONELEVEL_SCOPE, filter, attrs);
}

private static Attributes getAttributesEtudiantParis1(DirContext rootContextParis1, int cod_etu, String[] attrs) throws NamingException {
	String name = getDnUsersParis1();
	String filter = "(supannEtuId=" + cod_etu + ")";
	return getLdapAttributes(rootContextParis1, name, SearchControls.ONELEVEL_SCOPE, filter, attrs);
}

private static boolean isUserParis1(DirContext rootContextParis1, String uid) throws NamingException {
	SearchControls cons = new SearchControls();
	cons.setSearchScope(SearchControls.OBJECT_SCOPE);
	cons.setReturningAttributes(new String[0]);

	NamingEnumeration en;
	try {
		String name = getDnUserParis1(uid);
		String filter = "(objectClass=person)";
		en = rootContextParis1.search(name, filter, cons);
	}
	catch (NameNotFoundException e) {
		return false;
	}

	en.close();

	return true;
}

private static String getDnStructuresParis1() {
	return "ou=structures," + getDnParis1();
}

private static Attributes getAttributesStructureParis1(DirContext rootContextParis1, String supannCodeEntite, String[] attrs) throws NamingException {
	String name = getDnStructuresParis1();
	String filter = "(supannCodeEntite=" + ldapFilterEncode(supannCodeEntite) + ")";
	return getLdapAttributes(rootContextParis1, name, SearchControls.ONELEVEL_SCOPE, filter, attrs);
}

private static String getDescriptionStructureParis1(DirContext rootContextParis1, String supannCodeEntite) throws NamingException {
	Attributes attributes = getAttributesStructureParis1(rootContextParis1, supannCodeEntite, new String[] { "description" });
	if (attributes == null)
		return null;
		
	return getAttributeValue(attributes, "description");
}

private static String getEMailUserParis1(DirContext rootContextParis1, String uid) throws NamingException {
	Attributes attributes = getAttributesUserParis1(rootContextParis1, uid, new String[] { "mail" });
	if (attributes == null)
		return null;
		
	return getAttributeValue(attributes, "mail");
}
%>
