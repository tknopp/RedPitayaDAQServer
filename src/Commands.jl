export decimation

decimation(rp::RedPitaya) = query(rp,"RP:ADC:DECimation?", Int64)
