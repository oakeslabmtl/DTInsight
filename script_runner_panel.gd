extends Control

# On récupère les références vers nos nœuds pour pouvoir les modifier
@onready var path_line_edit = $VBoxContainer/InputContainer/PathLineEdit
@onready var file_dialog = $FileDialog

# Appelé quand on clique sur "Choisir fichier"
func _on_pick_button_pressed():
	# Ouvre la fenêtre de sélection de fichier
	file_dialog.popup_centered()

# Appelé quand l'utilisateur a choisi un fichier dans le FileDialog
func _on_file_dialog_file_selected(path):
	# On affiche le chemin dans le champ texte
	path_line_edit.text = path

# Appelé quand on clique sur "Run" (anciennement Apply)
func _on_run_button_pressed():
	var script_path = path_line_edit.text
	
	if script_path == "":
		printerr("Erreur : Aucun fichier sélectionné.")
		return

	if not FileAccess.file_exists(script_path):
		printerr("Erreur : Fichier Python introuvable à : ", script_path)
		return

	# Ton code d'exécution Python
	var command = "python"
	var args = [script_path]
	var output = []
	print("Lancement du script : ", script_path)
	
	# Exécution (bloquante avec true, attention si le script est long)
	var exit_code = OS.execute(command, args, output, true)
	
	if exit_code == 0:
		print("Script exécuté avec succès : ", output)
		# Optionnel : Fermer le popup après succès
		_on_back_button_pressed()
	else:
		printerr("Erreur Python (Code %s) : " % exit_code, output)

# Appelé quand on clique sur "Back"
func _on_back_button_pressed():
	# On cache simplement ce panneau
	get_parent().visible = false
