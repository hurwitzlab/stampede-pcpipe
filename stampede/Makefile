EMAIL = kyclark@email.arizona.edu
APPID = velvet-1.2.07

clean:
	find . \( -name \*.conf -o -name \*.out -o -name \*.log -o -name \*.params -o -name launcher-\* \) -exec rm {} \;

update:
	apps-addupdate -F app.json

bingz:
	rm -f bin.tgz && tar cvzf bin.tgz bin

rmbin:
	rm -rf bin

upload: bingz rmbin
	files-upload -F $(WORK)/$(APPID) kyclark/applications
