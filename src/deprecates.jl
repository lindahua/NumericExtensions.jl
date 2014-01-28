# Deprecated functions

### Deprecated at version v0.2.14

@Base.deprecate sum_fdiff sumfdiff
@Base.deprecate max_fdiff maxfdiff
@Base.deprecate min_fdiff minfdiff
@Base.deprecate wsum_fdiff wsumfdiff

@Base.deprecate sum_fdiff! sumfdiff!
@Base.deprecate max_fdiff! maxfdiff!
@Base.deprecate min_fdiff! minfdiff!
@Base.deprecate wsum_fdiff! wsumfdiff!

# @Base.deprecate asum sumabs  # since asum exists in BLAS, we keep both asum & sumabs
@Base.deprecate amax maxabs
@Base.deprecate amin minabs
@Base.deprecate sqsum sumsq

@Base.deprecate asum! sumabs!
@Base.deprecate amax! maxabs!
@Base.deprecate amin! minabs!
@Base.deprecate sqsum! sumsq!

@Base.deprecate adiffsum sumabsdiff
@Base.deprecate adiffmax maxabsdiff
@Base.deprecate adiffmin minabsdiff
@Base.deprecate sqdiffsum sumsqdiff

@Base.deprecate adiffsum! sumabsdiff!
@Base.deprecate adiffmax! maxabsdiff!
@Base.deprecate adiffmin! minabsdiff!
@Base.deprecate sqdiffsum! sumsqdiff!

@Base.deprecate sum_xlogx sumxlogx
@Base.deprecate sum_xlogy sumxlogy

@Base.deprecate sum_xlogx! sumxlogx!
@Base.deprecate sum_xlogy! sumxlogy!

@Base.deprecate wasum wsumabs
@Base.deprecate wadiffsum wsumabsdiff
@Base.deprecate wsqsum wsumsq
@Base.deprecate wsqdiffsum wsumsqdiff

@Base.deprecate wasum! wsumabs!
@Base.deprecate wadiffsum! wsumabsdiff!
@Base.deprecate wsqsum! wsumsq!
@Base.deprecate wsqdiffsum! wsumsqdiff!

@Base.deprecate vdiffnorm vnormdiff
@Base.deprecate vdiffnorm! vnormdiff!

@Base.deprecate unsafe_view view
