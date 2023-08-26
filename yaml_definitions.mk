# HACK:
# - DAVA denies whole integers in array-based values (position,
# angle, pivot etc), even if they are tagged !!float
# - Unfortunately, there's no way to multiply, let's say,
# float in form x.000000 by integer and return float in form x.000000 (or at least in x.0 form)
# - Therefore, in order to get desired x.000000 form, we concatenate multiplier/divider with .00001
# EXAMPLE: 42$(_YQ_forcefloat) -> 42.00001
# WARN: while it might not make visual difference, it certainly might
# break value-based conditions
_YQ_forcefloat = .00001
