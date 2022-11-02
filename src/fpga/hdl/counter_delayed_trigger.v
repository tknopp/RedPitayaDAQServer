`timescale 1ns / 1ps

module counter_delayed_trigger #
(
	parameter integer TRIGGER_COUNTER_WIDTH = 32,
	parameter integer TRIGGER_PRESAMPLES_WIDTH = 32,
	parameter integer ADC_WIDTH = 16
)
(
  input clk,
	input aresetn,
	input enable,
	input trigger_arm, // Arm the trigger
	input trigger_reset, // Unset the trigger after having triggered. Needs re-arming then.
	input [8-1:0] dios,
	input [ADC_WIDTH-1:0] adc0,
	input [ADC_WIDTH-1:0] adc1,
	input [5-1:0] source_select,
	input [TRIGGER_PRESAMPLES_WIDTH-1:0] trigger_presamples, // Number of samples the trigger should be fired prior to reaching the last counter value
	input [TRIGGER_COUNTER_WIDTH-1:0] reference_counter, // The reference that is used for determining when to start the trigger. Note: Splitted off to allow for e.g using an average value of the polled last counter values.
	output trigger, // The actual trigger
	output trigger_armed, // Arming status of the trigger
	output [TRIGGER_COUNTER_WIDTH-1:0] last_counter // The last full counter value
);

// Delayed trigger counter
reg [TRIGGER_COUNTER_WIDTH-1:0] delayed_trigger_counter = 0;
reg [TRIGGER_COUNTER_WIDTH-1:0] last_counter_out = 0;
reg counter_reset = 0; // Reset the counter to zero and save last counter state.
reg counter_reset_first = 0;
reg [ADC_WIDTH-1:0] curr_adc_val = 0;
reg last_sign = 0;
reg trigger_out = 0;
reg trigger_armed_int = 0;
reg trigger_armed_int_pre = 0;

always @(posedge clk)
begin
	if (~aresetn && enable)
	begin
		if (source_select[4] == 0) // The MSB defines if DIOs (== 0) or ADCs (== 1) should be selected
		begin
			counter_reset <= dios[source_select[3:0]];
		end
		else
		begin
			if (source_select[3:0] == 0)
			begin
				curr_adc_val <= adc0;
			end
			else
			begin
				curr_adc_val <= adc1;
			end

			last_sign <= curr_adc_val[ADC_WIDTH-1];
			if (last_sign != curr_adc_val[ADC_WIDTH-1])
			begin
				counter_reset <= 1;
			end
			else
			begin
				counter_reset <= 0;
			end
		end

		// Only react on first counter_reset == 1
		if ((counter_reset == 1) && (counter_reset_first == 1))
		begin
			if (trigger_armed_int == 0)
			begin
				last_counter_out <= delayed_trigger_counter;
				delayed_trigger_counter <= 0;
			end
			else // If the trigger is armed, we want the counter to run until we disarm/disable to always reach the reference counter
			begin
				last_counter_out <= delayed_trigger_counter + 1;
				delayed_trigger_counter <= delayed_trigger_counter + 1;
			end

			counter_reset_first <= 0;
		end
		else
		begin
			if (trigger_reset == 1)
			begin
				delayed_trigger_counter <= 0;
			end
			else
			begin
				delayed_trigger_counter <= delayed_trigger_counter + 1;

				// If the trigger is armed, the counter output should also run continuously
				if (trigger_armed_int == 1)
				begin
					last_counter_out <= delayed_trigger_counter + 1;
				end
			end
			
			if (counter_reset == 0 && counter_reset_first == 0)
			begin
				counter_reset_first <= 1;
			end
		end


		// DEBUG
		if (trigger_armed_int == 1)
		begin
			trigger_out <= 1;
		end
		else
		begin
			trigger_out <= 0;
		end

		// React to trigger arming internally in order to allow for short arm pulses
		if (trigger_arm == 1)
		begin
			trigger_armed_int_pre <= 1;
		end
		
		// Only do internal arming when we would not directly trigger due to already satisfying the condition
		if ((trigger_armed_int_pre == 1))// && ~(delayed_trigger_counter >= reference_counter-trigger_presamples-1))
		begin
			trigger_armed_int <= 1;
		end

		// /DEBUG
		
		/*
		// Set trigger if armed and presamples reached
		if ((trigger_armed_int == 1) && (delayed_trigger_counter >= reference_counter-trigger_presamples-1))
		begin
			if (trigger_reset == 1)
			begin
				trigger_out <= 0;
				trigger_armed_int <= 0;
				trigger_armed_int_pre <= 0;
			end
			else
			begin
				trigger_out <= 1;
			end
		end
		else
		begin
			if (trigger_reset == 1)
			begin
				trigger_out <= 0;
				trigger_armed_int <= 0;
				trigger_armed_int_pre <= 0;
			end
			else
			begin
				if ((trigger_armed_int == 1) && (trigger_out == 1))
				begin
					trigger_out <= 1; // Keep activated as long as the trigger is enabled and armed
				end
				else
				begin
					trigger_out <= 0; // Disable trigger when enabled but not armed
				end

				// React to trigger arming internally in order to allow for short arm pulses
				if (trigger_arm == 1)
				begin
					trigger_armed_int_pre <= 1;
				end
				else
				begin
					trigger_armed_int_pre <= 0; // Do not internally arm when disarming prior to hitting the condition below
				end
				
				// Only do internal arming when we would not directly trigger due to already satisfying the condition
				if ((trigger_armed_int_pre == 1) && ~(delayed_trigger_counter >= reference_counter-trigger_presamples-1))
				begin
					trigger_armed_int <= 1;
				end
			end
		end*/
	end
	else
	begin
		delayed_trigger_counter <= 0;
		last_counter_out <= 0;
		counter_reset <= 0;
		counter_reset_first <= 0;
		curr_adc_val <= 0;
		last_sign <= 0;
		trigger_armed_int <= 0;
		trigger_armed_int_pre <= 0;
		
		// If the counter trigger is not enabled, it should always be on due to and-ing the triggers
		if (enable == 1)
		begin
			trigger_out <= 0;
		end
		else
		begin
			trigger_out <= 1;
		end
	end
end

assign trigger = trigger_out;
assign trigger_armed = trigger_armed_int;
assign last_counter = last_counter_out;

endmodule
