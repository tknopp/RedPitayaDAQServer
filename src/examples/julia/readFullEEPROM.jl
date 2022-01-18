using RedPitayaDAQServer
ip = "192.168.2.16"
rp = RedPitaya(ip)

fields = ["fe_ch1_fs_g_hi",
"fe_ch2_fs_g_hi",
"fe_ch1_fs_g_lo",
"fe_ch2_fs_g_lo",
"fe_ch1_lo_offs",
"fe_ch2_lo_offs",
"be_ch1_fs",
"be_ch2_fs",
"be_ch1_dc_offs",
"be_ch2_dc_offs",
"fe_ch1_hi_offs",
"fe_ch2_hi_offs",
"low_filter_aa_ch1",
"low_filter_bb_ch1",
"low_filter_pp_ch1",
"low_filter_kk_ch1",
"low_filter_aa_ch2",
"low_filter_bb_ch2",
"low_filter_pp_ch2",
"low_filter_kk_ch2",
"hi_filter_aa_ch1",
"hi_filter_bb_ch1",
"hi_filter_pp_ch1",
"hi_filter_kk_ch1",
"hi_filter_aa_ch2",
"hi_filter_bb_ch2",
"hi_filter_pp_ch2",
"hi_filter_kk_ch2",
]

result = Dict{String, Int64}()

for field in fields
  result[field] = eepromField(rp, field)
end

@info result

disconnect(rp)