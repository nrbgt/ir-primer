define [], ->
  d3 = null

  # constants

  # gravitational acceleration (m/s^2)
  c_g0 = 9.80665
  # molar mass of air (kg/mol)
  c_M	= 0.0289644
  # universal gas constant for air (N-m/mol-K)
  c_R	= 8.31432
  # lapse rate(K/m)
  c_L	= 0.0065
  # m
  c_Tropopause = 11000


  Fresnel = (_d3)->
    d3 = _d3

    api = ->

    api
