<!DOCTYPE html>
<html>
	<body>
    	<?php
			$A=$_REQUEST['A'];
            $B=$_REQUEST['B'];
            $C=$_REQUEST['C'];

            if($A == 0)
            {
                $D = -$C/$B;
                print("X1: $D");
            }
            else if($C == 0)
            {
                print("X1: 0 <br>");
                $D = -$B/$A;
                print("X2: $D");
            }
            else if($A == 0 && $C == 0)
            {
                print("X = 0");
            }
            else
            {
               $n = pow($B,2)-4*($A*$C);
               if($n >= 0)
               {
                   $D = (-$B+sqrt($n))/(2*$A);
                   $D2 = (-$B-sqrt($n))/(2*$A);
    
                   print("X1: $D <br>");
                   print("X2: $D2");
               }
               else
               {
                   $D = -1*$n;
                   $R = sqrt($D);
                   $H1 = (-1*$B)/(2*$A);
                   $H2 = $R/(2*$A);

                   print("X1: $H1 + $H2 i <br>");
                   print("X2: $H1 + $H2 i");

               }

            }            
		?>	
	</body>
</html>