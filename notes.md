:vimgrep /<phrase_to_find>/ **/*.py
:copen
:cdo %s/<phrase_to_find>/<change_to>/gc | update
