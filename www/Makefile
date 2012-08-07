
# Compile all coffee scripts
coffee:
	coffee -c -o ./ ./

# Watch the coffee dir and compile scripts as they change
watch:
	coffee -w -c -o ./ ./

# Clean all targets
clean:
	rm `ls ./*.coffee | sed -e 's/\.\/\(.*\)\.coffee/\.\/\1.js/'`

# Make all...
all: coffee

