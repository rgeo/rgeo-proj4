# frozen_string_literal: true

require "test_helper"

class TestProj4 < Minitest::Test # :nodoc:
  def test_proj4_version
    assert_kind_of String, RGeo::CoordSys::Proj4.version
    # assert_match(/^\d+\.\d+(\.\d+)?$/, RGeo::CoordSys::Proj4.version)
  end

  def test_inheritance
    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert(proj.is_a?(RGeo::CoordSys::Proj4))
    assert(proj.is_a?(RGeo::CoordSys::CS::CoordinateSystem))
  end

  def test_create_wgs84
    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert_equal(true, proj.geographic?)
    assert_equal("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs", proj.original_str)
    assert_equal("+proj=longlat +datum=WGS84 +no_defs +type=crs", proj.canonical_str)
  end

  def test_valid
    assert_raises(RGeo::Error::InvalidProjection) do
      RGeo::CoordSys::Proj4.create("")
    end

    # will not raise for a valid projection, even though it is not a CRS
    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
    assert(proj._valid?)
  end

  def test_dimension_assigned_on_create
    proj = RGeo::CoordSys::Proj4.create("EPSG:3857")
    assert_equal(2, proj.dimension)
  end

  def test_is_crs
    crs_proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    non_crs_proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

    assert(crs_proj.crs?)
    refute(non_crs_proj.crs?)
  end

  def test_as_text
    proj = RGeo::CoordSys::Proj4.create("EPSG:3857")
    assert_equal(true, proj.as_text.include?("ID[\"EPSG\",3857]]"))
  end

  def test_auth_name
    proj = RGeo::CoordSys::Proj4.create("EPSG:4326")
    assert_equal("EPSG:4326", proj.auth_name)

    merc_wkt = <<~STR
      PROJCS["WGS 84 / Pseudo-Mercator",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]],PROJECTION["Mercator_1SP"],PARAMETER["central_meridian",0],PARAMETER["scale_factor",1],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["X",EAST],AXIS["Y",NORTH],EXTENSION["PROJ4","+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs"],AUTHORITY["EPSG","3857"]]
    STR
    proj = RGeo::CoordSys::Proj4.create(merc_wkt)
    assert_equal("EPSG:3857", proj.auth_name)

    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +lat_ts=5.0 +no_defs +type=crs")
    assert_nil(proj.auth_name)
  end

  def test_get_axis
    proj = RGeo::CoordSys::Proj4.create("EPSG:3857")
    assert_equal("Easting", proj.get_axis(0))
  end

  def test_get_units
    proj = RGeo::CoordSys::Proj4.create("EPSG:3857")
    assert_equal("metre", proj.get_units(0))
  end

  def test_get_wgs84_geographic
    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    proj2 = proj.get_geographic
    assert_nil(proj2.original_str)
    assert_equal(true, proj2.geographic?)
    coords = RGeo::CoordSys::Proj4.transform_coords(proj, proj2, 1, 2, 0)
    assert_equal([1, 2, 0], coords)
  end

  def test_identity_transform
    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert_equal([1, 2, 0], RGeo::CoordSys::Proj4.transform_coords(proj, proj, 1, 2, 0))
    assert_equal([1, 2], RGeo::CoordSys::Proj4.transform_coords(proj, proj, 1, 2, nil))
  end

  def test_simple_mercator_transform
    geography = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs", radians: true)
    projection = RGeo::CoordSys::Proj4.create("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs")
    assert_xy_close(project_merc(0, 0), RGeo::CoordSys::Proj4.transform_coords(geography, projection, 0, 0, nil))
    assert_xy_close(project_merc(0.01, 0.01), RGeo::CoordSys::Proj4.transform_coords(geography, projection, 0.01, 0.01, nil))
    assert_xy_close(project_merc(1, 1), RGeo::CoordSys::Proj4.transform_coords(geography, projection, 1, 1, nil))
    assert_xy_close(project_merc(-1, -1), RGeo::CoordSys::Proj4.transform_coords(geography, projection, -1, -1, nil))
    assert_xy_close(unproject_merc(0, 0), RGeo::CoordSys::Proj4.transform_coords(projection, geography, 0, 0, nil))
    assert_xy_close(unproject_merc(10_000, 10_000), RGeo::CoordSys::Proj4.transform_coords(projection, geography, 10_000, 10_000, nil))
    assert_xy_close(unproject_merc(-20_000_000, -20_000_000), RGeo::CoordSys::Proj4.transform_coords(projection, geography, -20_000_000, -20_000_000, nil))
  end

  def test_equivalence
    proj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    proj2 = RGeo::CoordSys::Proj4.create(" +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert_equal(proj1, proj2)
  end

  def test_hashes_equal_for_equivalent_objects
    proj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    proj2 = RGeo::CoordSys::Proj4.create(" +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert_equal(proj1.hash, proj2.hash)
  end

  def test_point_projection_cast
    geography = RGeo::Geos.factory(proj4: "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs", srid: 4326)
    projection = RGeo::Geos.factory(proj4: "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs +type=crs", srid: 27_700)
    proj_point = projection.parse_wkt("POINT(473600.5000000000000000 186659.7999999999883585)")
    geo_point = RGeo::Feature.cast(proj_point, project: true, factory: geography)
    assert_close_enough(-0.9393598527244420, geo_point.x)
    assert_close_enough(51.5740106527552697, geo_point.y)
  end

  def test_point_transform_lowlevel
    geography = RGeo::Geos.factory(proj4: "EPSG:4326", srid: 4326)
    projection = RGeo::Geos.factory(proj4: "EPSG:27700", srid: 27_700)
    proj_point = projection.parse_wkt("POINT(473600.5000000000000000 186659.7999999999883585)")
    geo_point = RGeo::CoordSys::Proj4.transform(projection.proj4, proj_point, geography.proj4, geography)
    assert_close_enough(-0.9393598527244420, geo_point.x)
    assert_close_enough(51.5740106527552697, geo_point.y)
  end

  def test_geocentric
    obj1 = RGeo::CoordSys::Proj4.create("+proj=geocent +ellps=WGS84 +type=crs")
    assert_equal(true, obj1.geocentric?)
  end

  def test_get_geographic
    projection = RGeo::CoordSys::Proj4.create("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs")
    geographic = projection.get_geographic
    expected = RGeo::CoordSys::Proj4.create("+proj=longlat +datum=WGS84 +no_defs +type=crs")
    assert_equal(expected, geographic)
  end

  def test_get_geographic_invalid_crs
    projection = RGeo::CoordSys::Proj4.create("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs")
    assert_raises(RGeo::Error::InvalidProjection) do
      projection.get_geographic
    end
  end

  def test_marshal_roundtrip
    obj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    dump = ::Marshal.dump(obj1)
    obj2 = ::Marshal.load(dump)
    assert_equal(obj1, obj2)
  end

  def test_dup
    obj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    obj2 = obj1.dup
    assert_equal(obj1, obj2)
  end

  def test_dup_of_get_geographic
    obj1 = RGeo::CoordSys::Proj4.create("+proj=latlong +datum=WGS84 +ellps=WGS84 +type=crs")
    obj2 = obj1.get_geographic
    obj3 = obj2.dup
    assert_equal(obj1, obj3)
  end

  def test_yaml_roundtrip
    obj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    dump = Psych.dump(obj1)
    obj2 = psych_load(dump)
    assert_equal(obj1, obj2)
  end

  def test_multi_polygon_transform
    from_wkt = <<~WKT
      MULTIPOLYGON (((784020.1897824854 6722964.293806808, 784037.326115887 6722975.889766449, 784054.4124898597 6722987.4862504555, 784071.3253728803 6722999.833471736, 784087.9890762889 6723013.43201526, 784104.3515158326 6723028.032402792, 784120.0308682051 6723043.388058192, 784134.7067634402 6723058.252599143, 784148.0652009461 6723072.12915206, 784159.8500073946 6723084.270231129, 784170.4972132337 6723095.42169378, 784180.7147581738 6723106.57680778, 784191.2547962071 6723119.22810715, 784202.6811317664 6723133.870442587, 784214.8759815434 6723150.754536163, 784227.4632711428 6723169.134420681, 784240.181080104 6723188.76220126, 784252.653331406 6723208.891610913, 784264.4439969584 6723228.777091963, 784275.221213894 6723248.171643657, 784284.4947434054 6723265.830027274, 784291.9327259483 6723281.505641706, 784298.2966828645 6723295.441536529, 784304.5985643048 6723309.128137981, 784311.9039028198 6723323.305754013, 784321.400262764 6723338.96387628, 784332.5380750942 6723356.106875415, 784344.6172699368 6723373.491695552, 784356.4424154337 6723390.378932787, 784367.2498671266 6723406.275734495, 784377.3693615372 6723421.178898737, 784388.1183614915 6723436.076913168, 784400.5524059066 6723451.709970812, 784415.821212109 6723469.317506157, 784433.52871879 6723488.153421866, 784452.4295334334 6723507.478738604, 784470.8843282094 6723526.058582454, 784487.5093193215 6723542.155666076, 784502.368705208 6723556.2690860145, 784516.2118965737 6723568.392673294, 784529.8525010797 6723579.019155646, 784544.3039663313 6723588.6392626595, 784559.558425686 6723597.503182013, 784575.0420814231 6723605.116047981, 784590.2174818617 6723611.732249156, 784604.44088523 6723616.857614208, 784617.4667343315 6723620.993872215, 784629.4128124788 6723623.890301049, 784640.2433945219 6723626.046546745, 784650.1783096731 6723627.461040881, 784659.2496563977 6723628.383231848, 784668.174745364 6723628.557302385, 784677.295429135 6723628.229868538, 784687.1470397501 6723626.897138264, 784697.8694634972 6723624.557523007, 784708.9673427406 6723621.7151745595, 784720.1830052689 6723618.622103866, 784731.0168432707 6723615.282357047, 784741.2968676833 6723611.447574695, 784750.6875940204 6723607.62045002, 784759.2168748197 6723603.550825318, 784766.4850260548 6723599.242197314, 784772.6897646365 6723594.44276483, 784777.9509994292 6723589.151908539, 784782.5863519495 6723583.1167083, 784786.961288117 6723575.834815708, 784791.1957108364 6723567.304911988, 784795.0519330226 6723557.778938195, 784798.2701595139 6723547.259102273, 784800.6684082886 6723535.497029851, 784802.1252754641 6723523.493236891, 784802.3182664857 6723509.751437822, 784801.0738921975 6723495.02257034, 784798.3037245563 6723478.308201662, 784793.7843121368 6723460.359494223, 784788.127298233 6723441.421170887, 784781.5909778869 6723422.49032073, 784774.7676320602 6723405.060836441, 784767.8870786584 6723389.130664893, 784760.0136832165 6723373.958494364, 784750.6308550239 6723357.550046889, 784738.7908438097 6723338.914192832, 784724.2353522843 6723317.053543477, 784707.9263733109 6723293.459249182, 784691.3040151886 6723270.616981534, 784678.976061013 6723254.533349478, 784675.7020984327 6723250.264152037, 784662.0126688856 6723233.892305451, 784649.2837293687 6723220.010606209, 784635.9831146887 6723205.883744532, 784620.9147737296 6723189.523616808, 784603.066757042 6723169.439897113, 784583.8285903189 6723146.869681756, 784564.9023020411 6723124.546537075, 784548.1255658776 6723104.703434426, 784535.1219723738 6723089.075222734, 784524.7717814728 6723076.4223131, 784515.8089956392 6723064.756996578, 784506.6315053658 6723051.344558031, 784496.0017910417 6723035.196530362, 784484.1696548788 6723016.310690788, 784471.7552316559 6722995.930974005, 784459.5206660905 6722975.549628993, 784448.0539926562 6722956.1609422555, 784437.0890500348 6722937.0180126205, 784425.7444064592 6722917.87821009, 784413.581909265 6722897.7459744355, 784399.9057362932 6722875.878055966, 784384.9121032218 6722853.021850328, 784369.1711865914 6722830.4220163785, 784353.2531560475 6722809.3224135395, 784337.6104054413 6722791.218522449, 784322.5484418896 6722775.607805061, 784307.9452370005 6722762.2414774075, 784293.907960408 6722749.619903008, 784280.3167058371 6722737.744000924, 784266.7832813218 6722725.617786431, 784252.6367154259 6722714.246345208, 784237.1790581255 6722702.636025109, 784220.0227432546 6722691.040340341, 784201.2640659683 6722680.207635438, 784181.8080638304 6722669.630677254, 784162.7381309723 6722659.799900687, 784144.7316082873 6722650.4597286945, 784127.9904608845 6722641.8582658805, 784112.1870717863 6722634.24811731, 784097.0116845404 6722627.631815419, 784082.0367635784 6722622.263114142, 784066.5107740257 6722617.898179469, 784049.562281599 6722614.294895784, 784030.169966921 6722611.21202143, 784007.4124334736 6722608.407665409, 783982.0348416284 6722605.375553562, 783956.031994045 6722602.848596293, 783931.7777657158 6722600.306678827, 783911.3326558475 6722597.982212025, 783895.3261667631 6722595.869746654, 783882.5713613448 6722594.229390163, 783871.9370069948 6722592.82083497, 783862.0705454329 6722592.405137684, 783852.3881866969 6722592.48741768, 783842.9662439888 6722593.816489142, 783833.6163697117 6722595.394868925, 783824.5126754063 6722597.720719233, 783815.7372182243 6722601.042863869, 783807.1558584626 6722604.863200681, 783798.5045521498 6722608.6839319905, 783789.9195677032 6722613.253662269, 783781.408773581 6722618.322403844, 783773.4617833871 6722623.885996045, 783766.5224957406 6722630.440308503, 783761.0905172229 6722637.981195592, 783757.2257988388 6722646.507948043, 783754.5607560001 6722656.273610394, 783752.9012929698 6722666.78019027, 783751.6257758558 6722677.783149326, 783750.6642590121 6722689.282982047, 783750.5205963242 6722701.775348378, 783751.4403425761 6722714.758220045, 783753.9994167396 6722728.976165743, 783758.3734330768 6722743.92825117, 783764.2483896465 6722759.117402907, 783771.1140676134 6722773.298952002, 783778.5244429724 6722785.726926091, 783786.4731507224 6722795.652316113, 783795.3626167289 6722804.570228123, 783806.1106181358 6722813.472546359, 783819.4393294791 6722823.851759641, 783835.784780275 6722836.453625396, 783855.1490952031 6722851.528146315, 783877.4038769861 6722868.077029753, 783902.287207964 6722885.852680436, 783929.6171073932 6722904.6068237815, 783958.7619492523 6722924.095006279, 783989.1600531361 6722944.072279992, 784020.1897824854 6722964.293806808)))
    WKT

    expected_wkt = <<~WKT
      MULTIPOLYGON (((4.118218755627164 47.60170379156289, 4.118448977204196 47.601805973530126, 4.118678534940962 47.60190816612819, 4.118905926445187 47.60201713721425, 4.119130239000034 47.602137401840714, 4.119350732561991 47.60226672130487, 4.119562279643725 47.60240292510987, 4.119760381760129 47.602534836457366, 4.119940766450274 47.60265802352209, 4.120099883387934 47.60276579154664, 4.120243675574546 47.602864797834464, 4.120381751289123 47.60296389167578, 4.120524401647747 47.60307641017696, 4.1206792230918 47.60320673506795, 4.120844695821001 47.60335713790226, 4.121015674523516 47.60352095280847, 4.121188626991511 47.60369598212229, 4.121358407596343 47.6038755573289, 4.121519072876696 47.60405302399376, 4.121666159672139 47.6042262015233, 4.121792908369146 47.60438394522743, 4.121894855712632 47.604524078149886, 4.121982181598614 47.604648690467165, 4.12206863465118 47.60477106695467, 4.1221685349109585 47.60489773425554, 4.122297873738788 47.60503744605652, 4.122449338617845 47.605190311909325, 4.122613378081979 47.60534523353263, 4.122773943424244 47.60549570907197, 4.1229207786225 47.605637400508286, 4.123058271072539 47.60577023686574, 4.123204140807506 47.605902946105985, 4.1233725753811115 47.60604205493235, 4.123579110484589 47.60619857117375, 4.123818334426022 47.60636583032464, 4.124073533537259 47.60653734078531, 4.124322657212557 47.6067021984214, 4.12454696003251 47.60684494470396, 4.124747390519252 47.60697006352369, 4.124933920648869 47.60707740338863, 4.125117471486614 47.607171294675446, 4.1253116234405445 47.607256024071496, 4.125516319230865 47.60733384427522, 4.125723828508561 47.60740037496817, 4.125927046719873 47.60745797466435, 4.126117312662281 47.607502278377524, 4.12629145339208 47.607537833362045, 4.126450988717112 47.60756236801652, 4.126595537946264 47.60758038390524, 4.126728026331922 47.607591838734415, 4.126848928382221 47.60759897350855, 4.12696774186902 47.60759939370998, 4.127089063176372 47.607595275020095, 4.12721992107008 47.60758201441576, 4.1273621768628335 47.60755957959112, 4.127509333773179 47.607532571637634, 4.127658010406887 47.60750329180743, 4.127801558448965 47.6074718407385, 4.127937641747194 47.60743600527765, 4.128061891054629 47.60740035293019, 4.128174629503187 47.607362628682054, 4.128270538563855 47.60732291544121, 4.128352201692467 47.60727892155719, 4.128421214594242 47.60723062606202, 4.128481756241614 47.60717571178843, 4.128538594875543 47.60710961049779, 4.128593325945347 47.60703229490001, 4.12864283411181 47.606946063096615, 4.128683662335624 47.60685096838951, 4.1287133415041914 47.60674479878031, 4.128730446327582 47.60663657474452, 4.128730400350534 47.60651287090283, 4.12871103771089 47.60638046816745, 4.1286709917989555 47.60623039180231, 4.1286074319812585 47.60606943114666, 4.128528544911781 47.60589971003511, 4.12843795784184 47.60573016922077, 4.12834383711759 47.60557417784705, 4.128249240737205 47.60543168787377, 4.128141576230785 47.60529614765896, 4.128013589713089 47.60514967466565, 4.127852480410862 47.604983470291636, 4.127654621852616 47.60478859088338, 4.127433100160773 47.604578333292125, 4.127207552702242 47.6043748839275, 4.127040439631529 47.604231711618105, 4.1269960595992075 47.6041937085045, 4.126810774800726 47.604048116759486, 4.1266387457513005 47.603924813236105, 4.126459063295951 47.60379937634074, 4.12625543352977 47.60365406621344, 4.126014107446576 47.60347559934526, 4.125753811737038 47.603274931331725, 4.125497715165237 47.60307644639734, 4.125270695849301 47.60290000610843, 4.125094687944448 47.602761016456824, 4.124954554859983 47.60264846468467, 4.124833072265048 47.60254462341365, 4.124708401823598 47.602425085035605, 4.124563888300137 47.6022811117407, 4.124402855809512 47.60211265142742, 4.124233792674795 47.6019308202541, 4.124067123775153 47.6017489511194, 4.123910862458261 47.60157591751184, 4.123761325261563 47.60140503128242, 4.123606736925808 47.60123422162304, 4.123441078513374 47.6010545843436, 4.123254950260203 47.60085951906136, 4.123051105029853 47.600655727296505, 4.12283736589651 47.60045433820814, 4.1226215553992125 47.600266473818536, 4.122409976169113 47.600105535932094, 4.122206598098991 47.59996696253224, 4.122009750033619 47.59984853015648, 4.121820574254132 47.59973672803746, 4.1216374752677325 47.59963157981595, 4.121455099215115 47.599524171035, 4.12126470771186 47.599423633478445, 4.121056825690699 47.599321113179776, 4.1208263440036 47.59921894125322, 4.120574685450808 47.59912384055464, 4.120313797142182 47.59903113014543, 4.120058187803079 47.59894508568199, 4.119816822075094 47.59886332048122, 4.119592434080051 47.598788041861845, 4.119380711913556 47.59872156523588, 4.119177534161067 47.59866395298263, 4.11897725959589 47.59861754353105, 4.118769841909666 47.59858023816971, 4.1185436397498805 47.598549968867985, 4.118285017553156 47.598524694470356, 4.117981669290857 47.59850235510115, 4.117643414975094 47.598478298880266, 4.1172969362144505 47.59845886783459, 4.116973722611339 47.59843907847789, 4.116701235577384 47.59842076048055, 4.116487850379359 47.59840378503848, 4.116317822103422 47.598390644547656, 4.116176052927202 47.598379320296104, 4.116044688380277 47.59837683416625, 4.1159158672276766 47.598378806397015, 4.1157907456926655 47.59839196681564, 4.115666629937241 47.598407361775465, 4.115545930387654 47.59842945273088, 4.1154297856573985 47.59846046873879, 4.115316317161896 47.59849594381532, 4.115201917855345 47.598531431223186, 4.115088541653725 47.59857365127661, 4.114976246243889 47.5986203530231, 4.114871545814292 47.59867143679682, 4.114780440220085 47.598731309167974, 4.1147095766656 47.59879986937365, 4.114659752796262 47.59887710344891, 4.114626124956965 47.59896533559062, 4.114606016928069 47.59906010840975, 4.114591111053066 47.59915929998284, 4.114580476714861 47.5992629236483, 4.1145809116106955 47.599375376461, 4.1145955890100785 47.59949210883598, 4.114632312421159 47.599619748905184, 4.114693324760918 47.59975376579318, 4.114774354515194 47.59988972557237, 4.11486837863548 47.60001649069972, 4.1149693218548045 47.60012740389, 4.115076958670597 47.60021572466339, 4.115196924980492 47.600294858185066, 4.115341619920819 47.600373614946925, 4.11552093405203 47.60046533580709, 4.115740810103948 47.60057667715522, 4.116001323866823 47.60070988857587, 4.116300579576221 47.600856001245816, 4.116635045838167 47.601012819782895, 4.117002254803573 47.601178132519784, 4.117393755828181 47.601349819454136, 4.117802028799536 47.60152574731618, 4.118218755627164 47.60170379156289)))
    WKT

    from_def = "+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs"
    from_proj = RGeo::CoordSys::Proj4.create(from_def)
    from_factory = RGeo::Cartesian.factory(srid: 2154, proj4: from_proj)

    to_def = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs"
    to_proj = RGeo::CoordSys::Proj4.create(to_def)
    to_factory = RGeo::Cartesian.factory(srid: 4326, proj4: to_proj)

    from_geom = from_factory.parse_wkt(from_wkt)
    to_geom = RGeo::CoordSys::Proj4.transform(from_proj, from_geom, to_proj, to_factory)
    expected_geom = to_factory.parse_wkt(expected_wkt)

    to_geom.coordinates.zip(expected_geom.coordinates).each do |p1, p2|
      p1.zip(p2).each do |r1, r2|
        r1.zip(r2).each do |c1, c2|
          assert_close_enough c1[0], c2[0]
          assert_close_enough c1[1], c2[1]
        end
      end
    end
  end

  private

  def project_merc(x, y)
    [x * 6_378_137.0, Math.log(Math.tan(Math::PI / 4.0 + y / 2.0)) * 6_378_137.0]
  end

  def unproject_merc(x, y)
    [x / 6_378_137.0, (2.0 * Math.atan(Math.exp(y / 6_378_137.0)) - Math::PI / 2.0)]
  end

  def assert_xy_close(xy1, xy2)
    assert_close_enough(xy1[0], xy2[0])
    assert_close_enough(xy1[1], xy2[1])
  end
end
