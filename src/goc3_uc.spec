{
    time_series_output {
        ac_line [{
            uid string
            on_status [int]
        }]
        simple_dispatchable_device [{
            uid string
            on_status [int]
            p_on [float]
            q [float]
            p_reg_res_up [float]
            p_reg_res_down [float]
            p_syn_res [float]
            p_nsyn_res [float]
            p_ramp_res_up_online [float]
            p_ramp_res_down_online [float]
            p_ramp_res_up_offline [float]
            p_ramp_res_down_offline [float]
            q_res_up [float]
            q_res_down [float]
        }]
        two_winding_transformer [{
            uid string
            on_status [int]
            ta [float]
            tm [float]
        }]
        shunt [{
            uid string
            step [int]
        }]
        dc_line [{uid string}]
        bus [{
            uid string
            va [float]
            vm [float]
        }]
    }
}
