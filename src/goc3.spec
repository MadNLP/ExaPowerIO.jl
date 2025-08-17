data {
    network {
        ac_line [{
            additional_shunt int
            b float
            connection_cost float
            disconnection_cost float
            fr_bus string
            initial_status {
                on_status int
            }
            mva_ub_em float
            mva_ub_nom float
            r float
            to_bus string
            uid string
            x float
        }]
        active_zonal_reserve [{
            NSYN float
            NSYN_vio_cost float
            RAMPING_RESERVE_DOWN_vio_cost float
            RAMPING_RESERVE_UP_vio_cost float
            REG_DOWN float
            REG_DOWN_vio_cost float
            REG_UP float
            REG_UP_vio_cost float
            SYN float
            SYN_vio_cost float
            uid string
        }]
        bus [{
            active_preserve_uids [ string ]
            base_nom_volt float
            con_loss_factor float
            initial_status {
                va float
                vm float
            }
            reactive_reserve_uids [ string ]
            uid string
            vm_lb float
            vm_ub float
        }]
        dc_line [{
            fr_bus string
            initial_status {
                pdc_fr float
                qdc_fr float
                qdc_to float
            }
            pdc_ub float
            qdc_fr_lb float
            qdc_fr_ub float
            qdc_to_lb float
            qdc_to_ub float
            to_bus string
            uid string
        }]
        general { base_norm_mva float }
        reactive_zonal_reserve [{
            REACT_DOWN_vio_cost float
            REACT_UP_vio_cost float
            uid string
        }]
        shunt [{
            bs float
            bus string
            gs float
            initial_status { step int }
            step_lb int
            step_ub int
            uid string
        }]
        simple_dispatchable_device [{
            bus string
            device_type string
            down_time_lb float
            energy_req_lb [[ float ]]
            energy_req_ub [[ float ]]
            in_service_time_lb float
            initial_status {
                accu_down_time float
                accu_up_time float
                on_status int
                p float
                q float
            }
            on_cost float
            p_nsyn_res_ub float
            p_ramp_down_ub float
            p_ramp_res_down_offline_ub float
            p_ramp_res_down_online_ub float
            p_ramp_res_up_offline_ub float
            p_ramp_res_up_online_ub float
            p_ramp_up_ub float
            p_reg_res_down_ub float
            p_reg_res_up_ub float
            p_shutdown_ramp_ub float
            p_startup_ramp_ub float
            p_syn_res_ub float
            q_bound_cap int
            q_linear_cap int
            shutdown_cost float
            startup_cost float
            startup_states [[ float ]]
            startups_ub [[ float ]]
            uid string
        }]
        two_winding_transformer [{
            additional_shunt int
            b float
            connection_cost float
            disconnection_cost float
            fr_bus string
            initial_status {
                on_status int
                ta float
                tm float
            }
            mva_ub_em float
            mva_ub_nom float
            r float
            ta_lb float
            ta_ub float
            tm_lb float
            tm_ub float
            to_bus string
            uid string
            x float
        }]
        violation_cost {
            e_vio_cost float
            p_bus_vio_cost float
            q_bus_vio_cost float
            s_vio_cost float
        }
    }
    reliability {
        contingency [{
            components [ string ]
            uid string
        }]
    }
    time_series_input {
        active_zonal_reserve [{
            RAMPING_RESERVE_DOWN [ float ]
            RAMPING_RESERVE_UP [ float ]
            uid string
        }]
        general {
            interval_duration [ float ]
            time_periods int
        }
        reactive_zonal_reserve [{
            REACT_DOWN [ float ]
            REACT_UP [ float ]
            uid string
        }]
        simple_dispatchable_device [{
            cost [[[ float ]]]
            on_status_lb [ int ]
            on_status_ub [ int ]
            p_lb [ float ]
            p_nsyn_res_cost [ float ]
            p_ramp_res_down_offline_cost [ float ]
            p_ramp_res_down_online_cost [ float ]
            p_ramp_res_up_offline_cost [ float ]
            p_ramp_res_up_online_cost [ float ]
            p_ramp_res_down_cost [ float ]
            p_ramp_res_up_cost [ float ]
            p_syn_res_cost [ float ]
            p_ub [ float ]
            q_lb [float ]
            q_res_down_cost [float ]
            q_res_up_cost [float ]
            q_ub [float ]
            uid string
        }]
    }
}
