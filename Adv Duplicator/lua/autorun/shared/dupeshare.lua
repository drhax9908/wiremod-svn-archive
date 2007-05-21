
dupeshare = {}
dupeshare.Version = 1.616

dupeshare.BaseDir		= "adv_duplicator"
dupeshare.PublicDirs	= { "=Public Folder=", "=Team Share Folder="}

//TODO
dupeshare.UsePWSys = false //server admins, set this to ture to use the folder password system


//this is only usfull for old saves, it doesn't do much for new ones.
dupeshare.DictionaryStart = 71
dupeshare.DictionarySize = 116
dupeshare.Dictionary = {
	[1]		= {"|MCl", "\"\n\t\t\t}\n\t\t\t\"class\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Class\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[2]		= {"|Mfz", "\"\n\t\t\t}\n\t\t\t\"frozen\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"frozen\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[3]		= {"|Mre", "\"\n\t\t\t}\n\t\t\t\"resistance\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"resistance\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[4]		= {"|Msp", "\"\n\t\t\t}\n\t\t\t\"speed\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"speed\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[5]		= {"|Mkd", "\"\n\t\t\t}\n\t\t\t\"key_d\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"key_d\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[6]		= {"|Mnc", "\"\n\t\t\t}\n\t\t\t\"NoCollide\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"nocollide\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[7]		= {"|Mdm", "\"\n\t\t\t}\n\t\t\t\"damageable\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"damageable\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[8]		= {"|Mkb", "\"\n\t\t\t}\n\t\t\t\"key_bck\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"key_bck\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[9]		= {"|Mfr", "\"\n\t\t\t}\n\t\t\t\"force\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"force\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[10]	= {"|Mky", "\"\n\t\t\t}\n\t\t\t\"key\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"key\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[11]	= {"|Mmd", "\"\n\t\t\t}\n\t\t\t\"model\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"model\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[12]	= {"|Mtg", "\"\n\t\t\t}\n\t\t\t\"toggle\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"toggle\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[13]	= {"|Mef", "\"\n\t\t\t}\n\t\t\t\"effect\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"effect\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[14]	= {"|ME1", "\"\n\t\t\t}\n\t\t\t\"Ent1\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Ent1\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[15]	= {"|ME2", "\"\n\t\t\t}\n\t\t\t\"Ent2\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Ent2\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[16]	= {"|MB1", "\"\n\t\t\t}\n\t\t\t\"Bone1\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Bone1\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[17]	= {"|MB2", "\"\n\t\t\t}\n\t\t\t\"Bone2\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Bone2\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[18]	= {"|Mtl", "\"\n\t\t\t}\n\t\t\t\"torquelimit\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"torquelimit\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[19]	= {"|Mty", "\"\n\t\t\t}\n\t\t\t\"type\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Type\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[20]	= {"|Mfl", "\"\n\t\t\t}\n\t\t\t\"forcelimit\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"forcelimit\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[21]	= {"|Mln", "\"\n\t\t\t}\n\t\t\t\"length\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"length\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[22]	= {"|MCI", "\"\n\t\t\t}\n\t\t\t\"ConstID\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"ConstID\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[23]	= {"|Mwd", "\"\n\t\t\t}\n\t\t\t\"width\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"width\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[24]	= {"|Mrg", "\"\n\t\t\t}\n\t\t\t\"rigid\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"rigid\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[25]	= {"|Mmt", "\"\n\t\t\t}\n\t\t\t\"material\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"material\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[26]	= {"|Mal", "\"\n\t\t\t}\n\t\t\t\"addlength\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"addlength\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[27]	= {"|MFI", "\"\n\t\t\t}\n\t\t\t\"FileInfo\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"FileInfo\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[28]	= {"|MND", "\"\n\t\t\t}\n\t\t\t\"NumOfDupeInfo\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"NumOfDupeInfo\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[29]	= {"|MNE", "\"\n\t\t\t}\n\t\t\t\"NumOfEnts\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"NumOfEnts\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[30]	= {"|MNC", "\"\n\t\t\t}\n\t\t\t\"NumOfConst\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"NumOfConst\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[31]	= {"|MCr", "\"\n\t\t\t}\n\t\t\t\"Creator\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Creator\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[32]	= {"|MDc", "\"\n\t\t\t}\n\t\t\t\"Desc\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Desc\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[33]	= {"|Mop", "\"\n\t\t\t}\n\t\t\t\"out_pos\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"out_pos\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[34]	= {"|Miw", "\"\n\t\t\t}\n\t\t\t\"ignore_world\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"ignore_world\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[35]	= {"|Mdz", "\"\n\t\t\t}\n\t\t\t\"default_zero\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"default_zero\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[36]	= {"|Msb", "\"\n\t\t\t}\n\t\t\t\"show_beam\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"show_beam\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[37]	= {"|Moa", "\"\n\t\t\t}\n\t\t\t\"out_ang\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"out_ang\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[38]	= {"|Mtw", "\"\n\t\t\t}\n\t\t\t\"trace_water\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"trace_water\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[39]	= {"|Mov", "\"\n\t\t\t}\n\t\t\t\"out_vel\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"out_vel\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[40]	= {"|Moc", "\"\n\t\t\t}\n\t\t\t\"out_col\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"out_col\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[41]	= {"|Moa", "\"\n\t\t\t}\n\t\t\t\"out_val\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"out_val\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[42]	= {"|Mod", "\"\n\t\t\t}\n\t\t\t\"out_dist\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"out_dist\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[43]	= {"|Mbd", "\"\n\t\t\t}\n\t\t\t\"doblastdamage\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"doblastdamage\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[44]	= {"|Mra", "\"\n\t\t\t}\n\t\t\t\"removeafter\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"removeafter\"\n\t\t\t\t\"__type\"\t\t\"Bool\"\n\t\t\t\t\"V\"\t\t\""},
	[45]	= {"|Mrd", "\"\n\t\t\t}\n\t\t\t\"radius\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"radius\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[46]	= {"|Mat", "\"\n\t\t\t}\n\t\t\t\"action\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"action\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[47]	= {"|Mkg", "\n\t\t\t\"keygroup\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"keygroup\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[48]	= {"|Mvo", "\"\n\t\t\t}\n\t\t\t\"value_off\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"value_off\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[49]	= {"|Mvn", "\"\n\t\t\t}\n\t\t\t\"value_on\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"value_on\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[50]	= {"|MAa", "\"\n\t\t\t}\n\t\t\t\"A\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"a\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[51]	= {"|MBb", "\"\n\t\t\t}\n\t\t\t\"B\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"b\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[52]	= {"|Mab", "\"\n\t\t\t}\n\t\t\t\"ab\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"ab\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[53]	= {"|Maa", "\"\n\t\t\t}\n\t\t\t\"aa\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"aa\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[54]	= {"|Mag", "\"\n\t\t\t}\n\t\t\t\"ag\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"ag\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[55]	= {"|Mbg", "\"\n\t\t\t}\n\t\t\t\"bg\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"bg\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[56]	= {"|Mba", "\"\n\t\t\t}\n\t\t\t\"ba\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"ba\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[57]	= {"|Mbb", "\"\n\t\t\t}\n\t\t\t\"bb\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"bb\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[58]	= {"|Mar", "\"\n\t\t\t}\n\t\t\t\"ar\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"ar\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[59]	= {"|Mbr", "\"\n\t\t\t}\n\t\t\t\"br\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"br\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[60]	= {"|MVe", "\"\n\t\t\t}\n\t\t\t\"Vel\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Vel\"\n\t\t\t\t\"__type\"\t\t\"Vector\"\n\t\t\t\t\"V\"\t\t\""},
	[61]	= {"|MaV", "\"\n\t\t\t}\n\t\t\t\"aVel\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"aVel\"\n\t\t\t\t\"__type\"\t\t\"Vector\"\n\t\t\t\t\"V\"\t\t\""},
	[62]	= {"|MSm", "\"\n\t\t\t}\n\t\t\t\"Smodel\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"Smodel\"\n\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\"V\"\t\t\""},
	[63]	= {"|MWw", "\"\n\t\t\t\t\t\t}\n\t\t\t\t\t\t\"width\"\n\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\"__name\"\t\t\"Width\"\n\t\t\t\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\t\t\t\"V\"\t\t\""},
	[64]	= {"|MWS", "\"\n\t\t\t\t\t\t}\n\t\t\t\t\t\t\"Src\"\n\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\"__name\"\t\t\"Src\"\n\t\t\t\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\t\t\t\"V\"\t\t\""},
	[65]	= {"|MWI", "\"\n\t\t\t\t\t\t}\n\t\t\t\t\t\t\"SrcId\"\n\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\"__name\"\t\t\"SrcId\"\n\t\t\t\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\t\t\t\"V\"\t\t\""},
	[66]	= {"|MWm", "\"\n\t\t\t\t\t\t}\n\t\t\t\t\t\t\"material\"\n\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\"__name\"\t\t\"material\"\n\t\t\t\t\t\t\t\"__type\"\t\t\"String\"\n\t\t\t\t\t\t\t\"V\"\t\t\""},
	[67]	= {"|MWD", "\"\n\t\t\t}\n\t\t\t\"DupeInfo\"\n\t\t\t{\n\t\t\t\t\"__name\"\t\t\"DupeInfo\"\n\t\t\t\t\"Wires\"\n\t\t\t\t{\n\t\t\t\t\t\"A\"\n\t\t\t\t\t{\n\t\t\t\t\t\t\"__name\"\t\t\"A\"\n\t\t\t\t\t\t\"SrcPos\"\n\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\"Y\"\t\t\""},
	[68]	= {"|MWB", "\"\n\t\t\t\t\t\t\t}\n\t\t\t\t\t\t\t\"B\"\n\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\"__name\"\t\t\"b\"\n\t\t\t\t\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\t\t\t\t\"V\"\t\t\""},
	[69]	= {"|MWg", "\"\n\t\t\t\t\t\t\t}\n\t\t\t\t\t\t\t\"g\"\n\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\"__name\"\t\t\"g\"\n\t\t\t\t\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\t\t\t\t\"V\"\t\t\""},
	[70]	= {"|MWr", "\"\n\t\t\t\t\t\t\t}\n\t\t\t\t\t\t\t\"r\"\n\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t\"__name\"\t\t\"r\"\n\t\t\t\t\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\t\t\t\t\"V\"\t\t\""},
	[71]	= {"|mn", "\t\t\"__name\"\t\t"},
	[72]	= {"|mt", "\t\t\"__type\"\t\t"},
	[73]	= {"|mv", "\t\t\t\"V\"\t\t"},
	[74]	= {"|mD", "\t\t\t\"DupeInfo\""},
	[75]	= {"|mN", "\"Number\"\n"},
	[76]	= {"|mS", "\"String\"\n"},
	[77]	= {"|mA", "\"Angle\"\n"},
	[78]	= {"|mV", "\"Vector\"\n"},
	[79]	= {"|mB", "\"Bool\"\n"},
	[80]	= {"|mC", "\"Class\""},
	[81]	= {"|mm", "\"material\""},
	[82]	= {"|mp", "\"prop_physics\""},
	[83]	= {"|VI", "\t\t\"VersionInfo\"\n\t\t\"FileVersion\"\n\t\t{\n\t\t\t\t\"__name\"\t\t\"FileVersion\"\n\t\t\t\t\"__type\"\t\t\"Number\"\n\t\t\t\t\"V\"\t\t\""},
	[84]	= {"|wm", "\"models"},
	[85]	= {"|nC", "\n\t\t\t\"NoCollide\"\n\t\t\t{\n\t"},
	[86]	= {"|nc", "\"nocollide\"\n"},
	[87]	= {"|HE", "\"HeadEntID\"\n"},
	[88]	= {"|ha", "\n\t}\n\t\"holdangle\"\n\t{\n"},
	[89]	= {"|qY", "\t\t\"Y\"\t\t\""},
	[90]	= {"|qz", "\t\t\"z\"\t\t\""},
	[91]	= {"|qx", "\t\t\"x\"\t\t\""},
	[92]	= {"|qA", "\t\t\"A\"\t\t\""},
	[93]	= {"|qB", "\t\t\"B\"\t\t\""},
	[94]	= {"|qg", "\t\t\"g\"\t\t\""},
	[95]	= {"|qr", "\t\t\"r\"\t\t\""},
	[96]	= {"|qp", "\t\t\"p\"\t\t\""},
	[97]	= {"|HA", "\"HoldAngle\"\n"},
	[98]	= {"�th", "\t\t{\n\t\t\t\"^Class\"\t\t\"Sgmod_thruster\"\n\t\t\t\"nocollide\"\t\t\"Btrue\"\n\t\t\t\"effect\"\t\t"},
	[99]	= {"�pp", "\t\t{\n\t\t\t\"^Class\"\t\t\"Sprop_physics\"\n\t\t\t\"^Model\"\t\t\"S"},
	[100]	= {"�LA", "\t\t\t\"^Local^Angle\"\t\t\"A"},
	[101]	= {"�LP", "\t\t\t\"^Local^Pos\"\t\t\"V"},
	[102]	= {"�po", "\t\t\t\"^Physics^Objects\""},
	[103]	= {"�Ps", "\t\t\t\"^Pos\"\t\t\"V"},
	[104]	= {"�An", "\t\t\t\"^Angle\"\t\t\"A"},
	[105]	= {"�EM", "\t\t\t\"^Entity^Mods\""},
	[106]	= {"�Cl", "\t\t\t\"^Class\"\t\t\"S"},
	[107]	= {"�CG", "\t\t\t\t\"^Collision^Group^Mod\"\t\t\"N"},
	[108]	= {"�RD", "\t\t\t\t\"^R^D^Dupe^Info\""},
	[109]	= {"|8", "\t\t\t\t\t\t\t\t"},
	[110]	= {"|7", "\t\t\t\t\t\t\t"},
	[111]	= {"|6", "\t\t\t\t\t\t"},
	[112]	= {"|5", "\t\t\t\t\t"},
	[113]	= {"|4", "\t\t\t\t"},
	[114]	= {"|3", "\t\t\t"},
	[115]	= {"|2", "\t\t"},
	[116]	= {"|N", "name"},
}

function dupeshare.Compress(str, ForConCommand)
	
	local beforelen = string.len(str)
	
	for k=dupeshare.DictionaryStart,dupeshare.DictionarySize do
		local entry = dupeshare.Dictionary[k]
		str = string.gsub(str, entry[2], entry[1])
	end
	
	if (ForConCommand) then //������������������������������������� unused special chars
		str = string.gsub(string.gsub(string.gsub(str,"�","|�"),"�","|�"),"�","|�") //incase it has any of these...
		str = string.gsub(string.gsub(string.gsub(str,"\n","�"),"\t","�"),"\"","�")
	end
	
	local afterlen = string.len(str)
	Msg("String Compressed: "..afterlen.." / "..beforelen.." ratio: "..(afterlen / beforelen).."%\n")
	
	return str
	
end

function dupeshare.DeCompress(str, FormConCommand)
	
	local afterlen = string.len(str)
	
	for k=dupeshare.DictionarySize,dupeshare.DictionaryStart,-1 do
		local entry = dupeshare.Dictionary[k]
		str = string.gsub(str, entry[1], entry[2])
	end
	
	if (FormConCommand) then
		str = string.gsub(string.gsub(string.gsub(str,"|�","�"),"|�","�"),"|�","�")
		str = string.gsub(string.gsub(string.gsub(str,"�","\n"),"�","\t"),"�","\"")
	end
	
	local beforelen = string.len(str)
	Msg("String Decompressed: "..afterlen.." / "..beforelen.." ratio: "..(afterlen / beforelen).."%\n")
	
	return str
	
end


//removes illegal characters from file names
dupeshare.BadChars = {"\\", "/", ":", "*", "?", "\"", "<", ">", "�", "|", "'"}

function dupeshare.ReplaceBadChar(str)
	for _,entry in pairs(dupeshare.BadChars) do
		str = string.gsub(str, entry, "_")
	end
	return str
end

function dupeshare.GetPlayerName(pl)
	local name = pl:GetName() or "unknown"
	name = dupeshare.ReplaceBadChar(name)
	return name
end


function dupeshare.NamedLikeAPublicDir(dir)
	dir = string.lower(dir)
	for k, v in pairs(dupeshare.PublicDirs) do
		if dir == string.lower(v) then return true end
	end
	return false
end


//checks if the player's active weapon is a duplicator
function dupeshare.CurrentToolIsDuplicator(tool, advdupeonly)
	if (tool) and (tool:GetClass() == "gmod_tool" )
	and ((tool:GetTable():GetToolObject().Name == "#AdvancedDuplicator")
	or ((tool:GetTable():GetToolObject().Name == "Duplicator") and !advdupeonly)) then
		return true
	else
		return false
	end
end




/*---------------------------------------------------------
	table util functions
---------------------------------------------------------*/
/*---------------------------------------------------------
Name: dupeshare.PrepareTableToSave( table )
Desc: Converts a table in to a lot tables to protect 
	vectors, angles, bools, numbers, and indexes
	from being horribly raped by TableToKeyValues
---------------------------------------------------------*/
function dupeshare.PrepareTableToSave_Old( t, done)
	
	local done = done or {}
	local tbl = {}
	
	for k, v in pairs ( t ) do
		if ( type( v ) == "table" and !done[ v ] ) then
			done[ v ] = true
			tbl[ k ] = dupeshare.PrepareTableToSave_Old ( v, done )
			tbl[k].__name = k
		else
			if ( type(v) == "Vector" ) then
				local x, y, z = v.x, v.y, v.z
				if y == 0 then y = nil end
				if z == 0 then z = nil end
				tbl[k] = { __type = "Vector", x = x, y = y, z = z, __name = k }
			elseif ( type(v) == "Angle" ) then
				local p,y,r = v.pitch, v.yaw, v.roll
				if p == 0 then p = nil end
				if y == 0 then y = nil end
				if r == 0 then r = nil end
				tbl[k] = { __type = "Angle", p = p, y = y, r = r, __name = k }
			elseif ( type(v) == "boolean" ) then
				tbl[k] = { __type = "Bool", v = tostring( v ), __name = k }
			elseif ( type(v) == "number" ) then
				tbl[k] = { __type = "Number", v = tostring( v ), __name = k }
			else
				tbl[k] = { __type = "String", v = tostring( v ), __name = k }
			end
		end
	end
	
	return tbl
end
function dupeshare.PrepareTableToSave( t, done)
	
	local done = done or {}
	local tbl = {}
	
	for k, v in pairs ( t ) do
		if ( type( v ) == "table" and !done[ v ] ) then
			done[ v ] = true
			tbl[ dupeshare.ProtectCase(k) ] = dupeshare.PrepareTableToSave( v, done )
		else
			if ( type(v) == "Vector" ) then
				local x, y, z = v.x, v.y, v.z
				tbl[ dupeshare.ProtectCase(k) ] = "V"..tostring(x).." "..tostring(y).." "..tostring(z)
			elseif ( type(v) == "Angle" ) then
				local p,y,r = v.pitch, v.yaw, v.roll
				tbl[ dupeshare.ProtectCase(k) ] = "A"..tostring(p).." "..tostring(y).." "..tostring(r)
			elseif ( type(v) == "boolean" ) then
				if v then
					tbl[ dupeshare.ProtectCase(k) ] = "B1"
				else
					tbl[ dupeshare.ProtectCase(k) ] = "B0"
				end
			elseif ( type(v) == "number" ) then
				tbl[ dupeshare.ProtectCase(k) ] = "N"..tostring( v )
			else
				tbl[ dupeshare.ProtectCase(k) ] = "S"..tostring( v )
			end
		end
	end
	
	return tbl
end

/*---------------------------------------------------------
   Name: dupeshare.RebuildTableFromLoad( table )
   Desc: Removes the protection added by PrepareTableToSave
		after table is loaded with KeyValuesToTable
---------------------------------------------------------*/
function dupeshare.RebuildTableFromLoad_Old( t, done )
	
	local done = done or {}
	local tbl = {}
	
	for k, v in pairs ( t ) do
		if ( type( v ) == "table" and !done[ v ] ) then
			done[ v ] = true
			if ( v.__type ) then
				if ( v.__type == "Vector" ) then
					tbl[ v.__name ] = Vector( v.x, v.y, v.z )
				elseif ( v.__type == "Angle" ) then
					tbl[ v.__name ] = Angle( v.p, v.y, v.r )
				elseif ( v.__type == "Bool" ) then
					tbl[ v.__name ] = util.tobool( v.v )
				elseif ( v.__type == "Number" ) then
					tbl[ v.__name ] = tonumber( v.v )
				elseif ( v.__type == "String" ) then
					tbl[ v.__name ] = tostring( v.v )
				end
			else
				tbl[ v.__name ] = dupeshare.RebuildTableFromLoad_Old ( v, done )
			end
		else
			if k != "__name" then //don't add the table names to output
				tbl[ k ] = v
			end
		end
	end
	
	return tbl
	
end
function dupeshare.RebuildTableFromLoad( t, done )
	
	local done = done or {}
	local tbl = {}
	
	for k, v in pairs ( t ) do
		if ( type( v ) == "table" and !done[ v ] ) then
			done[ v ] = true
			tbl[ dupeshare.UnprotectCase(k) ] = dupeshare.RebuildTableFromLoad( v, done )
		else
			local t = string.sub(v,1,1)
			local d = string.sub(v,2)
			if ( t == "V" ) then
				d = string.Explode(" ", d)
				--Msg("Vector: "..tostring(Vector( tonumber(d[1]), tonumber(d[2]), tonumber(d[3]) )).."\n")
				tbl[ dupeshare.UnprotectCase(k) ] = Vector( tonumber(d[1]), tonumber(d[2]), tonumber(d[3]) )
			elseif (t == "A" ) then
				d = string.Explode(" ", d)
				--Msg("Angle: "..tostring(Angle( d[1], d[2], d[3] )).."\n")
				tbl[ dupeshare.UnprotectCase(k) ] = Angle( tonumber(d[1]), tonumber(d[2]), tonumber(d[3]) )
			elseif ( t == "B" ) then
				tbl[ dupeshare.UnprotectCase(k)] = util.tobool( d )
			elseif ( t == "N" ) then
				tbl[ dupeshare.UnprotectCase(k) ] = tonumber( d )
			elseif ( t == "S" ) then
				tbl[ dupeshare.UnprotectCase(k) ] = tostring( d )
			else
				tbl[ dupeshare.UnprotectCase(k) ] = v
			end
		end
	end
	
	return tbl
	
end

//used by above functions to protect case from evil KeyValuesToTable
function dupeshare.ProtectCase(str)
	str2=""
	
	//mark numeric index and return
	if type(str) == "number" then return "#"..tostring(str) end
	
	//puts a carrot in front of capatials
	for i = 1, string.len(str) do
		local chr = string.sub(str, i, i)
		if (chr != string.lower(chr)) then chr = "^"..chr end
		str2 = str2..chr
	end
	--Msg("  str= "..str.." > "..str2)
	return str2
end

function dupeshare.UnprotectCase(str)
	local str2=""
	
	//index was a number, make it so and return
	if string.sub(str,1,1) == "#" then return tonumber(string.sub(str,2)) end
	
	//make char fallowing a carrot a capatical
	for i = 1, string.len(str) do
		local chr = string.sub(str, i, i)
		if (string.sub(str, i-1, i-1) == "^") then chr = string.upper(chr) end
		if chr != "^" then str2 = str2..chr end
	end
	--Msg("  str= "..str.." > "..str2)
	return str2
end





/*---------------------------------------------------------
	file and folder util functions
---------------------------------------------------------*/
/*---------------------------------------------------------
	Check if dir and filename exist and if so renames
	returns filepath (dir.."/"..filename..".txt")
---------------------------------------------------------*/
function dupeshare.FileNoOverWriteCheck( dir, filename )
	
	if !file.Exists(dir) then 
		file.CreateDir(dir)
	elseif !file.IsDir(dir) then
		local x = 0
		while x ~= nil do
			x = x + 1
			if not file.Exists(dir.."_"..tostring(x)) then
				dir = dir.."_"..tostring(x)
				file.CreateDir(dir)
				x = nil
			end
		end
	end
	
	if file.Exists(dir .. "/" .. filename .. ".txt") then
		local x = 0
		while x ~= nil do
			x = x + 1
			if not file.Exists(dir.."/"..filename.."_"..tostring(x)..".txt") then
				filename = filename.."_"..tostring(x)
				x = nil
			end
		end
	end
	
	local filepath = dir .. "/" .. filename .. ".txt"
	
	return filepath, filename, dir
end

function dupeshare.GetFileFromFilename(path)
	
	for i = string.len(path), 1, -1 do
		local str = string.sub(path, i, i)
		if str == "/" or str == "\\" then path = string.sub(path, (i + 1)) end
	end
	
	//removed .txt from the end if its there.
	if (string.sub(path, -4) == ".txt") then
		path = string.sub(path, 1, -5)
	end
	
	return path
end

function dupeshare.UpDir(path)
	
	for i = string.len(path), 1, -1 do
		local str = string.sub(path, i, i)
		if str == "/" then
			return string.sub(path, 1, (i - 1))
		end
	end
	
	return "" //if path/.. is root
end


//
// base255 conversion: based off the python module
//
//	the idea sounds good, but it can't handel negitive or float numbers
//
function dupeshare.number_to_base255(number)
	-- least significant "byte" will be first in result
	local list = {}
	-- take it apart as a series of numbers
	local str = ""
	while number != 0 do
		local n = math.fmod(number, 255)+1
		table.insert(list, n)
		Msg("====n = "..n.."\n")
		str = str .. string.char(math.floor(n))
		number = number / 255
	end
	-- reassemble it as a string and return it
	return str //string.char(unpack(list))
end

function dupeshare.base255_to_number(base255)
	local temp = String.byte(base255, 1, string.len(base255))
	local number = 0
	for _,byte in pairs(temp) do
		number = number * 255 + byte
	end
	return number
end


Msg("==== Advanced Duplicator v."..dupeshare.Version.." shared module installed! ====\n")
if (!duplicator.EntityClasses) then Msg("=== Error: Your gmod is out of date! ===\n=== You'll want to fix that or the Advanced Duplicator is not going to work. ===\n") end
