html: index.rst participants.rst
	sphinx-build . html

clean:
	rm -rf html
