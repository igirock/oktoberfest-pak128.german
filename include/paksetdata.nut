
function getDefaultProduction(nameOfIndustry)
{
	switch (nameOfIndustry)
	{
		case "Baustoffhof_1800": return -1;
	}
}



//			attraction_city   =  1,
//			attraction_land   =  2,
//			monument          =  3,
//			factory           =  4,
//			townhall          =  5,
//			others            =  6, ///< monorail foundation
//			headquarters      =  7,
//			dock              = 11, ///< dock, build on sloped coast
//			// in these, the extra data points to a waytype
//			depot             = 33,
//			generic_stop      = 34,
//			generic_extension = 35,
//			flat_dock         = 36, ///< dock, but can start on a flat coast line
//			// city buildings
//			city_res          = 37, ///< residential city buildings
//			city_com          = 38, ///< commercial  city buildings
//			city_ind          = 39  ///< industrial  city buildings

function getIndustrySize(nameOfIndustry)
{
	//local factories = building_desc_x.get_building_list(4);
	//foreach (fac in factories)
	//{
	//	if (fac.get_name() == nameOfIndustry)
	//		return fac.get_size(0);
	//}
	//
	//return null;


	local s = {};
	switch (nameOfIndustry)
	{
		case "Baustoffhof_1800": 
			s.x <- 2;
			s.y <- 2;
			return s;
		
		case "Oktoberfest":
			s.x <- 5;
			s.y <- 5;
			return s;
			
		case "Gasthof_1800":
			s.x <- 2;
			s.y <- 2;
			return s;
			
		case "Gastwirtschaft_mit_Laden":
			s.x <- 2;
			s.y <- 1;
			return s;
			
		case "Geraete_und_Haushaltsartikel":
			s.x <- 1;
			s.y <- 2;
			return s;
			
		case "Apotheke1800_NIC":
			s.x <- 1;
			s.y <- 1;
			return s;
			
		case "VWAutohaus_NIC":
			s.x <- 2;
			s.y <- 2;
			return s;
			
		case "AVL_Marktplatz_NIC":
			s.x <- 2;
			s.y <- 2;
			return s;
		
		case "Kaufhaus_NIC":
			s.x <- 2;
			s.y <- 2;
			return s;
			
		case "Verwaltung_Muenchen_1965":
			s.x <- 2;
			s.y <- 2;
			return s;
	}
}