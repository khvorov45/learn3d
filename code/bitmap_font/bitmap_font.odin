// Texture representation taken from https://github.com/nakst/luigi
// Public domain.

// Font taken from https://commons.wikimedia.org/wiki/File:Codepage-437.png
// Public domain.

package bitmap_font

GLYPH_HEIGHT_PX :: 16
GLYPH_WIDTH_PX :: 8
ROWS_PER_GLYPH :: 16

get_texture_u8_slice :: proc() -> []u8 {
	data := cast([^]u8)&BITMAP_TEXTURE
	result := data[:len(BITMAP_TEXTURE) * 8]
	return result
}

get_glyph_u8_slice :: proc(ch: u8) -> []u8 {
	data := cast([^]u8)&BITMAP_TEXTURE
	glyph_start := int(ch) * ROWS_PER_GLYPH
	glyph_data := data[glyph_start:glyph_start + ROWS_PER_GLYPH]
	return glyph_data
}

BITMAP_TEXTURE := [?]u64{
	0x0000000000000000,
	0x0000000000000000,
	0xBD8181A5817E0000,
	0x000000007E818199,
	0xC3FFFFDBFF7E0000,
	0x000000007EFFFFE7,
	0x7F7F7F3600000000,
	0x00000000081C3E7F,
	0x7F3E1C0800000000,
	0x0000000000081C3E,
	0xE7E73C3C18000000,
	0x000000003C1818E7,
	0xFFFF7E3C18000000,
	0x000000003C18187E,
	0x3C18000000000000,
	0x000000000000183C,
	0xC3E7FFFFFFFFFFFF,
	0xFFFFFFFFFFFFE7C3,
	0x42663C0000000000,
	0x00000000003C6642,
	0xBD99C3FFFFFFFFFF,
	0xFFFFFFFFFFC399BD,
	0x331E4C5870780000,
	0x000000001E333333,
	0x3C666666663C0000,
	0x0000000018187E18,
	0x0C0C0CFCCCFC0000,
	0x00000000070F0E0C,
	0xC6C6C6FEC6FE0000,
	0x0000000367E7E6C6,
	0xE73CDB1818000000,
	0x000000001818DB3C,
	0x1F7F1F0F07030100,
	0x000000000103070F,
	0x7C7F7C7870604000,
	0x0000000040607078,
	0x1818187E3C180000,
	0x0000000000183C7E,
	0x6666666666660000,
	0x0000000066660066,
	0xD8DEDBDBDBFE0000,
	0x00000000D8D8D8D8,
	0x6363361C06633E00,
	0x0000003E63301C36,
	0x0000000000000000,
	0x000000007F7F7F7F,
	0x1818187E3C180000,
	0x000000007E183C7E,
	0x1818187E3C180000,
	0x0000000018181818,
	0x1818181818180000,
	0x00000000183C7E18,
	0x7F30180000000000,
	0x0000000000001830,
	0x7F060C0000000000,
	0x0000000000000C06,
	0x0303000000000000,
	0x0000000000007F03,
	0xFF66240000000000,
	0x0000000000002466,
	0x3E1C1C0800000000,
	0x00000000007F7F3E,
	0x3E3E7F7F00000000,
	0x0000000000081C1C,
	0x0000000000000000,
	0x0000000000000000,
	0x18183C3C3C180000,
	0x0000000018180018,
	0x0000002466666600,
	0x0000000000000000,
	0x36367F3636000000,
	0x0000000036367F36,
	0x603E0343633E1818,
	0x000018183E636160,
	0x1830634300000000,
	0x000000006163060C,
	0x3B6E1C36361C0000,
	0x000000006E333333,
	0x000000060C0C0C00,
	0x0000000000000000,
	0x0C0C0C0C18300000,
	0x0000000030180C0C,
	0x30303030180C0000,
	0x000000000C183030,
	0xFF3C660000000000,
	0x000000000000663C,
	0x7E18180000000000,
	0x0000000000001818,
	0x0000000000000000,
	0x0000000C18181800,
	0x7F00000000000000,
	0x0000000000000000,
	0x0000000000000000,
	0x0000000018180000,
	0x1830604000000000,
	0x000000000103060C,
	0xDBDBC3C3663C0000,
	0x000000003C66C3C3,
	0x1818181E1C180000,
	0x000000007E181818,
	0x0C183060633E0000,
	0x000000007F630306,
	0x603C6060633E0000,
	0x000000003E636060,
	0x7F33363C38300000,
	0x0000000078303030,
	0x603F0303037F0000,
	0x000000003E636060,
	0x633F0303061C0000,
	0x000000003E636363,
	0x18306060637F0000,
	0x000000000C0C0C0C,
	0x633E6363633E0000,
	0x000000003E636363,
	0x607E6363633E0000,
	0x000000001E306060,
	0x0000181800000000,
	0x0000000000181800,
	0x0000181800000000,
	0x000000000C181800,
	0x060C183060000000,
	0x000000006030180C,
	0x00007E0000000000,
	0x000000000000007E,
	0x6030180C06000000,
	0x00000000060C1830,
	0x18183063633E0000,
	0x0000000018180018,
	0x7B7B63633E000000,
	0x000000003E033B7B,
	0x7F6363361C080000,
	0x0000000063636363,
	0x663E6666663F0000,
	0x000000003F666666,
	0x03030343663C0000,
	0x000000003C664303,
	0x66666666361F0000,
	0x000000001F366666,
	0x161E1646667F0000,
	0x000000007F664606,
	0x161E1646667F0000,
	0x000000000F060606,
	0x7B030343663C0000,
	0x000000005C666363,
	0x637F636363630000,
	0x0000000063636363,
	0x18181818183C0000,
	0x000000003C181818,
	0x3030303030780000,
	0x000000001E333333,
	0x1E1E366666670000,
	0x0000000067666636,
	0x06060606060F0000,
	0x000000007F664606,
	0xC3DBFFFFE7C30000,
	0x00000000C3C3C3C3,
	0x737B7F6F67630000,
	0x0000000063636363,
	0x63636363633E0000,
	0x000000003E636363,
	0x063E6666663F0000,
	0x000000000F060606,
	0x63636363633E0000,
	0x000070303E7B6B63,
	0x363E6666663F0000,
	0x0000000067666666,
	0x301C0663633E0000,
	0x000000003E636360,
	0x18181899DBFF0000,
	0x000000003C181818,
	0x6363636363630000,
	0x000000003E636363,
	0xC3C3C3C3C3C30000,
	0x00000000183C66C3,
	0xDBC3C3C3C3C30000,
	0x000000006666FFDB,
	0x18183C66C3C30000,
	0x00000000C3C3663C,
	0x183C66C3C3C30000,
	0x000000003C181818,
	0x0C183061C3FF0000,
	0x00000000FFC38306,
	0x0C0C0C0C0C3C0000,
	0x000000003C0C0C0C,
	0x1C0E070301000000,
	0x0000000040607038,
	0x30303030303C0000,
	0x000000003C303030,
	0x0000000063361C08,
	0x0000000000000000,
	0x0000000000000000,
	0x0000FF0000000000,
	0x0000000000180C0C,
	0x0000000000000000,
	0x3E301E0000000000,
	0x000000006E333333,
	0x66361E0606070000,
	0x000000003E666666,
	0x03633E0000000000,
	0x000000003E630303,
	0x33363C3030380000,
	0x000000006E333333,
	0x7F633E0000000000,
	0x000000003E630303,
	0x060F0626361C0000,
	0x000000000F060606,
	0x33336E0000000000,
	0x001E33303E333333,
	0x666E360606070000,
	0x0000000067666666,
	0x18181C0018180000,
	0x000000003C181818,
	0x6060700060600000,
	0x003C666660606060,
	0x1E36660606070000,
	0x000000006766361E,
	0x18181818181C0000,
	0x000000003C181818,
	0xDBFF670000000000,
	0x00000000DBDBDBDB,
	0x66663B0000000000,
	0x0000000066666666,
	0x63633E0000000000,
	0x000000003E636363,
	0x66663B0000000000,
	0x000F06063E666666,
	0x33336E0000000000,
	0x007830303E333333,
	0x666E3B0000000000,
	0x000000000F060606,
	0x06633E0000000000,
	0x000000003E63301C,
	0x0C0C3F0C0C080000,
	0x00000000386C0C0C,
	0x3333330000000000,
	0x000000006E333333,
	0xC3C3C30000000000,
	0x00000000183C66C3,
	0xC3C3C30000000000,
	0x0000000066FFDBDB,
	0x3C66C30000000000,
	0x00000000C3663C18,
	0x6363630000000000,
	0x001F30607E636363,
	0x18337F0000000000,
	0x000000007F63060C,
	0x180E181818700000,
	0x0000000070181818,
	0x1800181818180000,
	0x0000000018181818,
	0x18701818180E0000,
	0x000000000E181818,
	0x000000003B6E0000,
	0x0000000000000000,
	0x63361C0800000000,
	0x00000000007F6363,
}
