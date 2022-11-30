html: index.rst participants.rst buliding_the_kernel.rst
	sphinx-build . html

clean:
	rm -rf html
