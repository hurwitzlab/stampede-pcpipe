EMAIL = kyclark@email.arizona.edu
APPID = pcpipe-0.0.2

clean:
	find . \( -name \*.conf -o -name \*.out -o -name \*.log -o -name \*.params -o -name launcher-\* \) -exec rm {} \;

update:
	apps-addupdate -F app.json

upload: 
	files-upload -F $(WORK)/$(APPID) kyclark/applications

test: clean
	sbatch test.sh
