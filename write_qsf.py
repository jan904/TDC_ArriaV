elements = 512
y_start = 26

with open('placement.qsf', 'w') as f:
    y = y_start
    i = 0
    for j in range(0, elements, 2):
        ff1 = 'set_location_assignment LABCELL_X42_Y' + str(y) + '_N' + str(i) + ' -to "delay_line:delay_line_inst|fdr:\\\latch_1:' + str(j) + ':ff1|q~0" \n'
        ff2 = 'set_location_assignment LABCELL_X42_Y' + str(y) + '_N' + str(i+3) + ' -to "delay_line:delay_line_inst|fdr:\\\latch_1:' + str(j+1) + ':ff1|q~0" \n'
        ff3 = 'set_location_assignment FF_X42_Y' + str(y) + '_N' + str(i+1) + ' -to "delay_line:delay_line_inst|fdr:\\\latch_1:' + str(j) + ':ff2|q" \n'
        ff4 = 'set_location_assignment FF_X42_Y' + str(y) + '_N' + str(i+2) + ' -to "delay_line:delay_line_inst|fdr:\\\latch_1:' + str(j) + ':ff1|q" \n'
        ff5 = 'set_location_assignment FF_X42_Y' + str(y) + '_N' + str(i+4) + ' -to "delay_line:delay_line_inst|fdr:\\\latch_1:' + str(j+1) + ':ff2|q" \n'
        ff6 = 'set_location_assignment FF_X42_Y' + str(y) + '_N' + str(i+5) + ' -to "delay_line:delay_line_inst|fdr:\\\latch_1:' + str(j+1) + ':ff1|q" \n'
        
        i += 6
        if i >= 60:
            i = 0
            y -= 1

        for ff in [ff1, ff2, ff3, ff4, ff5, ff6, '\n']:
            f.write(ff)

with open('placement.qsf', 'a') as f:
        y = y_start
        i = 0
        k = 0
        for j in range(-2, elements, 2):

            if j < elements-2:
                ff1 = 'set_location_assignment FF_X41_Y' + str(y) + '_N' + str(k+2) + ' -to "delay_line:delay_line_inst|carry4:delayblock|interm[' + str(j+2) + ']" \n'
                ff2 = 'set_location_assignment FF_X41_Y' + str(y) + '_N' + str(k+5) + ' -to "delay_line:delay_line_inst|carry4:delayblock|interm[' + str(j+1+2) + ']" \n'
            else:
                ff1 = ''
                ff2 = ''

            if j >= 0:
                ff3 = 'set_location_assignment FF_X41_Y' + str(y) + '_N' + str(i+1) + ' -to "delay_line:delay_line_inst|carry4:delayblock|Sum_vector[' + str(j) + ']" \n'
                ff4 = 'set_location_assignment FF_X41_Y' + str(y) + '_N' + str(i+4) + ' -to "delay_line:delay_line_inst|carry4:delayblock|Sum_vector[' + str(j+1) + ']" \n'
            else:
                ff3 = ''
                ff4 = ''

            i += 6
            k += 6
            if i >= 60:
                i = 0
            if k >= 60:
                k = 0
                y -= 1

            for ff in [ff1, ff2, ff3, ff4, '\n']:
                f.write(ff)



