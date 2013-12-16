# reduction

#################################################
#
#    generation of reduction codes
#
#################################################

## 
#  compose the code for sequential reduction
#
#  s:       the symbol of accumulator
#  tf:      the function to generate each term 
#  uf:      the function to generate updating code for accumulator
#  ifirst:  the symbol of starting index
#  ilast:   the symbol of last index
#
function compose_seqreduc(s::Symbol, tf::Function, uf::Function, ifirst::Symbol, ilast::Symbol)
	@gensym i t
	term_expr = kf(i)
	upd_expr = uf(s, t)
	quote
		for $i = $ifirst : $ilast
			@inbounds $t = $term_expr
			$upd_expr
		end
	end
end

## 
#  compose the code for pairwise reduction
#
#  s:         the symbol of accumulator
#  tf:        the function to generate each term
#  uf:        the function to generate updating code for accumulator
#  ifirst:    the symbol of starting index
#  ilast:     the symbol of last index
#
function compose_pwreduc()
	@gensym i t
	term_expr = kf(i)
	upd_expr = uf(s, t)
end



