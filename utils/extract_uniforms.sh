#how do you feel about bash?
for shader in ../assets/shaders/*; do
	glslang -i "$shader" | sed -n "s/^0:?[^']*'\(.*\)'.*uniform.*/\1/p"
done
