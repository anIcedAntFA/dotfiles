function take
		mkdir -p -- "$argv[1]" && cd -- "$argv[1]"
		# Or, if using the variable:
		# eval $take
end