/*
 * scripts.js
 *
 * Copyright (C) 2013 Université Paris 1 Panthéon-Sorbonne
 *
 * Auteurs :
 *  VRI   Vincent Rivière
 *
 * Ce fichier est distribué sous licence GPLv3.
 * Voir le fichier license.txt pour les détails.
 */

// Changer l'état "sélectionné" d'un objet
function toggleSelect(obj) {
	if (obj.className == '')
		obj.className = 'selected';
	else
		obj.className = '';
}
