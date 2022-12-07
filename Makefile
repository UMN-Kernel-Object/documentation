
html:	rst/*.rst
	sphinx-build rst html

clean:
	rm -rf html
