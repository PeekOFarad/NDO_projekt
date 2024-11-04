-- ROM with synchonous read (inferring Block RAM)
-- character ROM
--   - 8-by-12 font
--   - 85 characters
--               16K bits: 1 BRAM

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity fontROM_8x12 is
	generic(
		addrWidth: integer := 10;
		dataWidth: integer := 8
	);
	port(
		clkA: in std_logic;
		addrA: in std_logic_vector(addrWidth-1 downto 0);
		dataOutA: out std_logic_vector(dataWidth-1 downto 0)
	);
end fontROM_8x12;

architecture Behavioral of fontROM_8x12 is
   
	type rom_type is array (0 to 2**addrWidth-1) of std_logic_vector(dataWidth-1 downto 0);

	-- ROM definition
	signal ROM: rom_type := (
		-- 0. code x00
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00000000", -- 3
		"00000000", -- 4
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 1. code x01
		"00111100", -- 0   ****  
		"00111100", -- 1   ****   
		"00111100", -- 2   ****   
		"00111100", -- 3   ****   
		"00111100", -- 4   ****   
		"00111100", -- 5   ****   
		"00111100", -- 6   ****   
		"00111100", -- 7   ****   
		"00111100", -- 8   ****   
		"00111100", -- 9   ****   
		"00111100", -- a   ****   
		"00111100", -- b   ****  
		-- 2. code x02
		"00000000", -- 0 
		"00000000", -- 1 
		"00000000", -- 2 
		"00000000", -- 3 
		"11111111", -- 4 ********
		"11111111", -- 5 ********
		"11111111", -- 6 ********
		"11111111", -- 7 ********
		"00000000", -- 8 
		"00000000", -- 9 
		"00000000", -- a 
		"00000000", -- b 
		-- 3. code x03
		"00111100", -- 0   ****  
		"00111100", -- 1   ****  
		"00111100", -- 2   ****  
		"00111100", -- 3   ****  
		"11111111", -- 4 ********
		"11111111", -- 5 ********
		"11111111", -- 6 ********
		"11111111", -- 7 ********
		"00111100", -- 8   ****  
		"00111100", -- 9   ****  
		"00111100", -- a   ****  
		"00111100", -- b   ****   
		-- 4. code x04 
		"00111100", -- 0   ****  
		"00111100", -- 1   ****  
		"00111100", -- 2   ****  
		"00111100", -- 3   ****  
		"11111100", -- 4 ******
		"11111100", -- 5 ******
		"11111100", -- 6 ******
		"11111100", -- 7 ******
		"00111100", -- 8   ****  
		"00111100", -- 9   ****  
		"00111100", -- a   ****  
		"00111100", -- b   **** 
		-- 5. code x05
		"00111100", -- 0   ****  
		"00111100", -- 1   ****  
		"00111100", -- 2   ****  
		"00111100", -- 3   ****  
		"00111111", -- 4   ******
		"00111111", -- 5   ******
		"00111111", -- 6   ******
		"00111111", -- 7   ******
		"00111100", -- 8   ****  
		"00111100", -- 9   ****  
		"00111100", -- a   ****  
		"00111100", -- b   ****  
		-- 6. code x06    
		"00000000", -- 0     
		"00000000", -- 1     
		"00000000", -- 2     
		"00000000", -- 3     
		"00111111", -- 4   ****** 
		"00111111", -- 5   ****** 
		"00111111", -- 6   ****** 
		"00111111", -- 7   ****** 
		"00111100", -- 8   ****   
		"00111100", -- 9   ****   
		"00111100", -- a   ****  
		"00111100", -- b   ****  
		-- 7. code x07   
		"00000000", -- 0     
		"00000000", -- 1     
		"00000000", -- 2     
		"00000000", -- 3     
		"11111100", -- 4 ******
		"11111100", -- 5 ******
		"11111100", -- 6 ******
		"11111100", -- 7 ******
		"00111100", -- 8   ****  
		"00111100", -- 9   ****  
		"00111100", -- a   ****  
		"00111100", -- b   ****   
		-- 8. code x08 
		"00111100", -- 0   ****    
		"00111100", -- 1   ****    
		"00111100", -- 2   ****    
		"00111100", -- 3   ****    
		"11111100", -- 4 ****** 
		"11111100", -- 5 ****** 
		"11111100", -- 6 ****** 
		"11111100", -- 7 ****** 
		"00000000", -- 8       
		"00000000", -- 9     
		"00000000", -- a     
		"00000000", -- b        
		-- 9. code x09 
		"00111100", -- 0   ****  
		"00111100", -- 1   ****  
		"00111100", -- 2   ****  
		"00111100", -- 3   ****  
		"00111111", -- 4 	 ******
		"00111111", -- 5 	 ******
		"00111111", -- 6 	 ******
		"00111111", -- 7 	 ******
		"00000000", -- 8     
		"00000000", -- 9     
		"00000000", -- a     
		"00000000", -- b         
		-- 10. code x0a
		"00000000", -- 0
		"00011000", -- 1    **
		"00111100", -- 2   ****
		"01111110", -- 3  ******
		"00011000", -- 4    **
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00011000", -- a    **
		"00000000", -- b
		-- 11. code x0b
		"00000000", -- 0
		"00011000", -- 1    **
		"00011000", -- 2    **
		"00011000", -- 3    **
		"00011000", -- 4    **
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"01111110", -- 8  ******
		"00111100", -- 9   ****
		"00011000", -- a    **
		"00000000", -- b
		-- 12. code x0c
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00011000", -- 3    **
		"00001100", -- 4     **
		"11111110", -- 5 *******
		"00001100", -- 6     **
		"00011000", -- 7    **
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 13. code x0d
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00110000", -- 3   **
		"01100000", -- 4  **
		"11111110", -- 5 *******
		"01100000", -- 6  **
		"00110000", -- 7   **
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 14. code x0e
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00100100", -- 3   *  *
		"01100110", -- 4  **  **
		"11111111", -- 5 ********
		"01100110", -- 6  **  **
		"00100100", -- 7   *  *
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 15. code x0f
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00010000", -- 3    *
		"00111000", -- 4   ***
		"00111000", -- 5   ***
		"01111100", -- 6  *****
		"01111100", -- 7  *****
		"11111110", -- 8 *******
		"11111110", -- 9 *******
		"00000000", -- a
		"00000000", -- b
		-- 16. code x10
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"11111110", -- 3 *******
		"11111110", -- 4 *******
		"01111100", -- 5  *****
		"01111100", -- 6  *****
		"00111000", -- 7   ***
		"00111000", -- 8   ***
		"00010000", -- 9    *
		"00000000", -- a
		"00000000", -- b
		-- 17. code x11
		"00000000", -- 0
		"00011000", -- 1    **
		"00111100", -- 2   ****
		"00111100", -- 3   ****
		"00111100", -- 4   ****
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00000000", -- 8
		"00011000", -- 9    **
		"00011000", -- a    **
		"00000000", -- b
		-- 18. code x12
		"00000000", -- 0
		"01100110", -- 1  **  **
		"01100110", -- 2  **  **
		"01100110", -- 3  **  **
		"00100100", -- 4   *  *
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 19. code x13
		"00000000", -- 0
		"00000000", -- 1
		"01101100", -- 2  ** **
		"01101100", -- 3  ** **
		"11111110", -- 4 *******
		"01101100", -- 5  ** **
		"01101100", -- 6  ** **
		"01101100", -- 7  ** **
		"11111110", -- 8 *******
		"01101100", -- 9  ** **
		"01101100", -- a  ** **
		"00000000", -- b
		-- 20. code x15
		"00000000", -- 0
		"00000000", -- 1
		"11000010", -- 2 **    *
		"11000110", -- 3 **   **
		"00001100", -- 4     **
		"00011000", -- 5    **
		"00110000", -- 6   **
		"01100000", -- 7  **
		"11000110", -- 8 **   **
		"10000110", -- 9 *    **
		"00000000", -- a
		"00000000", -- b
		-- 21. code x16
		"00000000", -- 0
		"00111000", -- 1   ***
		"01101100", -- 2  ** **
		"01101100", -- 3  ** **
		"00111000", -- 4   ***
		"01110110", -- 5  *** **
		"11011100", -- 6 ** ***
		"11001100", -- 7 **  **
		"11001100", -- 8 **  **
		"11001100", -- 9 **  **
		"01110110", -- a  *** **
		"00000000", -- b
		-- 22. code x17
		"00000000", -- 0
		"00110000", -- 1   **
		"00110000", -- 2   **
		"00110000", -- 3   **
		"01100000", -- 4  **
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 23. code x18
		"00000000", -- 0
		"00001100", -- 1     **
		"00011000", -- 2    **
		"00110000", -- 3   **
		"00110000", -- 4   **
		"00110000", -- 5   **
		"00110000", -- 6   **
		"00110000", -- 7   **
		"00110000", -- 8   **
		"00011000", -- 9    **
		"00001100", -- a     **
		"00000000", -- b
		-- 24. code x19
		"00000000", -- 0
		"00110000", -- 1   **
		"00011000", -- 2    **
		"00001100", -- 3     **
		"00001100", -- 4     **
		"00001100", -- 5     **
		"00001100", -- 6     **
		"00001100", -- 7     **
		"00001100", -- 8     **
		"00011000", -- 9    **
		"00110000", -- a   **
		"00000000", -- b
		-- 25. code x1a
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00000000", -- 3
		"01100110", -- 4  **  **
		"00111100", -- 5   ****
		"11111111", -- 6 ********
		"00111100", -- 7   ****
		"01100110", -- 8  **  **
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 26. code x1b
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00000000", -- 3
		"00011000", -- 4    **
		"00011000", -- 5    **
		"01111110", -- 6  ******
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 27. code x1c
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00000000", -- 3
		"00000000", -- 4
		"00000000", -- 5
		"00000000", -- 6
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00110000", -- a   **
		"00000000", -- b
		-- 28. code x1d
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00000000", -- 3
		"00000000", -- 4
		"00000000", -- 5
		"01111110", -- 6  ******
		"00000000", -- 7
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 29. code x1e
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00000000", -- 3
		"00000000", -- 4
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00000000", -- 8
		"00011000", -- 9    **
		"00011000", -- a    **
		"00000000", -- b
		-- 30. code x1f
		"00000000", -- 0
		"00000000", -- 1
		"00000010", -- 2       *
		"00000110", -- 3      **
		"00001100", -- 4     **
		"00011000", -- 5    **
		"00110000", -- 6   **
		"01100000", -- 7  **
		"11000000", -- 8 **
		"10000000", -- 9 *
		"00000000", -- a
		"00000000", -- b
		-- 31. code x20
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11001110", -- 4 **  ***
		"11011110", -- 5 ** ****
		"11110110", -- 6 **** **
		"11100110", -- 7 ***  **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"01111100", -- a  *****
		"00000000", -- b
		-- 32. code x21
		"00000000", -- 0
		"00011000", -- 1	  **
		"00111000", -- 2	 ***
		"01111000", -- 3  ****
		"00011000", -- 4    **
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    ** 
		"01111110", -- a  ******
		"00000000", -- b   
		-- 33. code x22
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"00000110", -- 3      **
		"00001100", -- 4     **
		"00011000", -- 5    **
		"00110000", -- 6   **
		"01100000", -- 7  **
		"11000000", -- 8 **
		"11000110", -- 9 **   **
		"11111110", -- a *******
		"00000000", -- b
		-- 34. code x23
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"00000110", -- 3      **
		"00000110", -- 4      **
		"00111100", -- 5   ****
		"00000110", -- 6      **
		"00000110", -- 7      **
		"00000110", -- 8      **
		"11000110", -- 9 **   **
		"01111100", -- a  *****
		"00000000", -- b
		-- 35. code x24
		"00000000", -- 0
		"00001100", -- 1     **
		"00011100", -- 2    ***
		"00111100", -- 3   ****
		"01101100", -- 4  ** **
		"11001100", -- 5 **  **
		"11111110", -- 6 *******
		"00001100", -- 7     **
		"00001100", -- 8     **
		"00001100", -- 9     **
		"00011110", -- a    ****
		"00000000", -- b
		-- 36. code x25
		"00000000", -- 0
		"11111110", -- 1 *******
		"11000000", -- 2 **
		"11000000", -- 3 **
		"11000000", -- 4 **
		"11111100", -- 5 ******
		"00000110", -- 6      **
		"00000110", -- 7      **
		"00000110", -- 8      **
		"11000110", -- 9 **   **
		"01111100", -- a  *****
		"00000000", -- b
		-- 37. code x26
		"00000000", -- 0
		"00111000", -- 1   ***
		"01100000", -- 2  **
		"11000000", -- 3 **
		"11000000", -- 4 **
		"11111100", -- 5 ******
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"01111100", -- a  *****
		"00000000", -- b
		-- 38. code x27
		"00000000", -- 0
		"11111110", -- 1 *******
		"11000110", -- 2 **   **
		"00000110", -- 3      **
		"00000110", -- 4      **
		"00001100", -- 5     **
		"00011000", -- 6    **
		"00110000", -- 7   **
		"00110000", -- 8   **
		"00110000", -- 9   **
		"00110000", -- a   **
		"00000000", -- b
		-- 39. code x28
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"01111100", -- 5  *****
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"01111100", -- a  *****
		"00000000", -- b
		-- 40. code x29
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"01111110", -- 5  ******
		"00000110", -- 6      **
		"00000110", -- 7      **
		"00000110", -- 8      **
		"00001100", -- 9     **
		"01111000", -- a  ****
		"00000000", -- b
		-- 41. code x2a
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00011000", -- 3    **
		"00011000", -- 4    **
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00000000", -- a
		"00000000", -- b
		-- 42. code x2b
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00011000", -- 3    **
		"00011000", -- 4    **
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00110000", -- a   **
		"00000000", -- b
		-- 43. code x2c
		"00000000", -- 0
		"00000000", -- 1
		"00000110", -- 2      **
		"00001100", -- 3     **
		"00011000", -- 4    **
		"00110000", -- 5   **
		"01100000", -- 6  **
		"00110000", -- 7   **
		"00011000", -- 8    **
		"00001100", -- 9     **
		"00000110", -- a      **
		"00000000", -- b
		-- 44. code x2d
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00000000", -- 3
		"01111110", -- 4  ******
		"00000000", -- 5
		"00000000", -- 6
		"01111110", -- 7  ******
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 45. code x2e
		"00000000", -- 0
		"00000000", -- 1
		"01100000", -- 2  **
		"00110000", -- 3   **
		"00011000", -- 4    **
		"00001100", -- 5     **
		"00000110", -- 6      **
		"00001100", -- 7     **
		"00011000", -- 8    **
		"00110000", -- 9   **
		"01100000", -- a  **
		"00000000", -- b
		-- 46. code x2f
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"00001100", -- 4     **
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00000000", -- 8
		"00011000", -- 9    **
		"00011000", -- a    **
		"00000000", -- b
		-- 47. code x30
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11011110", -- 5 ** ****
		"11011110", -- 6 ** ****
		"11011110", -- 7 ** ****
		"11011100", -- 8 ** ***
		"11000000", -- 9 **
		"01111100", -- a  *****
		"00000000", -- b
		-- 48. code x31
		"00000000", -- 0
		"00010000", -- 1    *
		"00111000", -- 2   ***
		"01101100", -- 3  ** **
		"11000110", -- 4 **   **
		"11000110", -- 5 **   **
		"11111110", -- 6 *******
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"00000000", -- b
		-- 49. code x32
		"00000000", -- 0
		"11111100", -- 1 ******
		"01100110", -- 2  **  **
		"01100110", -- 3  **  **
		"01100110", -- 4  **  **
		"01111100", -- 5  *****
		"01100110", -- 6  **  **
		"01100110", -- 7  **  **
		"01100110", -- 8  **  **
		"01100110", -- 9  **  **
		"11111100", -- a ******
		"00000000", -- b
		-- 50. code x33
		"00000000", -- 0
		"00111100", -- 1   ****
		"01100110", -- 2  **  **
		"11000010", -- 3 **    *
		"11000000", -- 4 **
		"11000000", -- 5 **
		"11000000", -- 6 **
		"11000000", -- 7 **
		"11000010", -- 8 **    *
		"01100110", -- 9  **  **
		"00111100", -- a   ****
		"00000000", -- b
		-- 51. code x34
		"00000000", -- 0
		"11111000", -- 1 *****
		"01101100", -- 2  ** **
		"01100110", -- 3  **  **
		"01100110", -- 4  **  **
		"01100110", -- 5  **  **
		"01100110", -- 6  **  **
		"01100110", -- 7  **  **
		"01100110", -- 8  **  **
		"01101100", -- 9  ** **
		"11111000", -- a *****
		"00000000", -- b
		-- 52. code x35
		"00000000", -- 0
		"11111110", -- 1 *******
		"01100110", -- 2  **  **
		"01100010", -- 3  **   *
		"01101000", -- 4  ** *
		"01111000", -- 5  ****
		"01101000", -- 6  ** *
		"01100000", -- 7  **
		"01100010", -- 8  **   *
		"01100110", -- 9  **  **
		"11111110", -- a *******
		"00000000", -- b
		-- 53. code x36
		"00000000", -- 0
		"11111110", -- 1 *******
		"01100110", -- 2  **  **
		"01100010", -- 3  **   *
		"01101000", -- 4  ** *
		"01111000", -- 5  ****
		"01101000", -- 6  ** *
		"01100000", -- 7  **
		"01100000", -- 8  **
		"01100000", -- 9  **
		"11110000", -- a ****
		"00000000", -- b
		-- 54. code x37
		"00000000", -- 0
		"00111100", -- 1   ****
		"01100110", -- 2  **  **
		"11000010", -- 3 **    *
		"11000000", -- 4 **
		"11000000", -- 5 **
		"11011110", -- 6 ** ****
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"01100110", -- 9  **  **
		"00111010", -- a   *** *
		"00000000", -- b
		-- 55. code x38
		"00000000", -- 0
		"11000110", -- 1 **   **
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11111110", -- 5 *******
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"00000000", -- b
		-- 56. code x39
		"00000000", -- 0
		"00111100", -- 1   ****
		"00011000", -- 2    **
		"00011000", -- 3    **
		"00011000", -- 4    **
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00111100", -- a   ****
		"00000000", -- b
		-- 57. code x3a
		"00000000", -- 0
		"00011110", -- 1    ****
		"00001100", -- 2     **
		"00001100", -- 3     **
		"00001100", -- 4     **
		"00001100", -- 5     **
		"00001100", -- 6     **
		"11001100", -- 7 **  **
		"11001100", -- 8 **  **
		"11001100", -- 9 **  **
		"01111000", -- a  ****
		"00000000", -- b
		-- 58. code x3b
		"00000000", -- 0
		"11100110", -- 1 ***  **
		"01100110", -- 2  **  **
		"01100110", -- 3  **  **
		"01101100", -- 4  ** **
		"01111000", -- 5  ****
		"01111000", -- 6  ****
		"01101100", -- 7  ** **
		"01100110", -- 8  **  **
		"01100110", -- 9  **  **
		"11100110", -- a ***  **
		"00000000", -- b
		-- 59. code x3c
		"00000000", -- 0
		"11110000", -- 1 ****
		"01100000", -- 2  **
		"01100000", -- 3  **
		"01100000", -- 4  **
		"01100000", -- 5  **
		"01100000", -- 6  **
		"01100000", -- 7  **
		"01100010", -- 8  **   *
		"01100110", -- 9  **  **
		"11111110", -- a *******
		"00000000", -- b
		-- 60. code x3d
		"00000000", -- 0
		"11000011", -- 1 **    **
		"11100111", -- 2 ***  ***
		"11111111", -- 3 ********
		"11111111", -- 4 ********
		"11011011", -- 5 ** ** **
		"11000011", -- 6 **    **
		"11000011", -- 7 **    **
		"11000011", -- 8 **    **
		"11000011", -- 9 **    **
		"11000011", -- a **    **
		"00000000", -- b
		-- 61. code x3e
		"00000000", -- 0
		"11000110", -- 1 **   **
		"11100110", -- 2 ***  **
		"11110110", -- 3 **** **
		"11111110", -- 4 *******
		"11011110", -- 5 ** ****
		"11001110", -- 6 **  ***
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"11000110", -- a **   **
		"00000000", -- b
		-- 62. code x3f
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11000110", -- 5 **   **
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"01111100", -- a  *****
		"00000000", -- b
		-- 63. code x40
		"00000000", -- 0
		"11111100", -- 1 ******
		"01100110", -- 2  **  **
		"01100110", -- 3  **  **
		"01100110", -- 4  **  **
		"01111100", -- 5  *****
		"01100000", -- 6  **
		"01100000", -- 7  **
		"01100000", -- 8  **
		"01100000", -- 9  **
		"11110000", -- a ****
		"00000000", -- b
		-- 64. code x41
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11000110", -- 5 **   **
		"11010110", -- 6 ** * **
		"11011110", -- 7 ** ****
		"01111100", -- 8  *****
		"00001100", -- 9     **
		"00001110", -- a     ***
		"00000000", -- b
		-- 65. code x42
		"00000000", -- 0
		"11111100", -- 1 ******
		"01100110", -- 2  **  **
		"01100110", -- 3  **  **
		"01100110", -- 4  **  **
		"01111100", -- 5  *****
		"01101100", -- 6  ** **
		"01100110", -- 7  **  **
		"01100110", -- 8  **  **
		"01100110", -- 9  **  **
		"11100110", -- a ***  **
		"00000000", -- b
		-- 66. code x43
		"00000000", -- 0
		"01111100", -- 1  *****
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"01100000", -- 4  **
		"00111000", -- 5   ***
		"00001100", -- 6     **
		"00000110", -- 7      **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"01111100", -- a  *****
		"00000000", -- b
		-- 67. code x44
		"00000000", -- 0
		"11111111", -- 1 ********
		"11011011", -- 2 ** ** **
		"10011001", -- 3 *  **  *
		"00011000", -- 4    **
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00111100", -- a   ****
		"00000000", -- b
		-- 68. code x45
		"00000000", -- 0
		"11000110", -- 1 **   **
		"11000110", -- 2 **   **
		"11000110", -- 3 **   **
		"11000110", -- 4 **   **
		"11000110", -- 5 **   **
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11000110", -- 8 **   **
		"11000110", -- 9 **   **
		"01111100", -- a  *****
		"00000000", -- b
		-- 69. code x46
		"00000000", -- 0
		"11000011", -- 1 **    **
		"11000011", -- 2 **    **
		"11000011", -- 3 **    **
		"11000011", -- 4 **    **
		"11000011", -- 5 **    **
		"11000011", -- 6 **    **
		"11000011", -- 7 **    **
		"01100110", -- 8  **  **
		"00111100", -- 9   ****
		"00011000", -- a    **
		"00000000", -- b
		-- 70. code x47
		"00000000", -- 0
		"11000011", -- 1 **    **
		"11000011", -- 2 **    **
		"11000011", -- 3 **    **
		"11000011", -- 4 **    **
		"11000011", -- 5 **    **
		"11011011", -- 6 ** ** **
		"11011011", -- 7 ** ** **
		"11111111", -- 8 ********
		"01100110", -- 9  **  **
		"01100110", -- a  **  **
		"00000000", -- b
		-- 71. code x48
		"00000000", -- 0
		"11000011", -- 1 **    **
		"11000011", -- 2 **    **
		"01100110", -- 3  **  **
		"00111100", -- 4   ****
		"00011000", -- 5    **
		"00011000", -- 6    **
		"00111100", -- 7   ****
		"01100110", -- 8  **  **
		"11000011", -- 9 **    **
		"11000011", -- a **    **
		"00000000", -- b
		-- 72. code x49
		"00000000", -- 0
		"11000011", -- 1 **    **
		"11000011", -- 2 **    **
		"11000011", -- 3 **    **
		"01100110", -- 4  **  **
		"00111100", -- 5   ****
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00111100", -- a   ****
		"00000000", -- b
		-- 73. code x4a
		"00000000", -- 0
		"11111111", -- 1 ********
		"11000011", -- 2 **    **
		"10000110", -- 3 *    **
		"00001100", -- 4     **
		"00011000", -- 5    **
		"00110000", -- 6   **
		"01100000", -- 7  **
		"11000001", -- 8 **     *
		"11000011", -- 9 **    **
		"11111111", -- a ********
		"00000000", -- b
		-- 74. code x4b
		"00000000", -- 0
		"00111100", -- 1   ****
		"00110000", -- 2   **
		"00110000", -- 3   **
		"00110000", -- 4   **
		"00110000", -- 5   **
		"00110000", -- 6   **
		"00110000", -- 7   **
		"00110000", -- 8   **
		"00110000", -- 9   **
		"00111100", -- a   ****
		"00000000", -- b
		-- 75. code x4c
		"00000000", -- 0
		"00000000", -- 1
		"10000000", -- 2 *
		"11000000", -- 3 **
		"11100000", -- 4 ***
		"01110000", -- 5  ***
		"00111000", -- 6   ***
		"00011100", -- 7    ***
		"00001110", -- 8     ***
		"00000110", -- 9      **
		"00000010", -- a       *
		"00000000", -- b
		-- 76. code x4d
		"00000000", -- 0
		"00111100", -- 1   ****
		"00001100", -- 2     **
		"00001100", -- 3     **
		"00001100", -- 4     **
		"00001100", -- 5     **
		"00001100", -- 6     **
		"00001100", -- 7     **
		"00001100", -- 8     **
		"00001100", -- 9     **
		"00111100", -- a   ****
		"00000000", -- b
		-- 77. code x4e
		"00010000", -- 0    *
		"00111000", -- 1   ***
		"01101100", -- 2  ** **
		"11000110", -- 3 **   **
		"00000000", -- 4
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 78. code x4f
		"00000000", -- 0
		"00000000", -- 1
		"00000000", -- 2
		"00000000", -- 3
		"00000000", -- 4
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00000000", -- 8
		"00000000", -- 9
		"11111111", -- a ********
		"00000000", -- b
		-- 79. code x50 
		"00110000", -- 0   **
		"00110000", -- 1   **
		"00011000", -- 2    **
		"00000000", -- 3
		"00000000", -- 4
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 80. code x51
		"00000000", -- 0
		"00001110", -- 1     ***
		"00011000", -- 2    **
		"00011000", -- 3    **
		"00011000", -- 4    **
		"01110000", -- 5  ***
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00001110", -- a     ***
		"00000000", -- b
		-- 81. code x52
		"00000000", -- 0
		"00011000", -- 1    **
		"00011000", -- 2    **
		"00011000", -- 3    **
		"00011000", -- 4    **
		"00000000", -- 5
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"00011000", -- a    **
		"00000000", -- b
		-- 82. code x53
		"00000000", -- 0
		"01110000", -- 1  ***
		"00011000", -- 2    **
		"00011000", -- 3    **
		"00011000", -- 4    **
		"00001110", -- 5     ***
		"00011000", -- 6    **
		"00011000", -- 7    **
		"00011000", -- 8    **
		"00011000", -- 9    **
		"01110000", -- a  ***
		"00000000", -- b
		-- 83. code x54
		"00000000", -- 0
		"00000000", -- 1
		"01110110", -- 2  *** **
		"11011100", -- 3 ** ***
		"00000000", -- 4
		"00000000", -- 5
		"00000000", -- 6
		"00000000", -- 7
		"00000000", -- 8
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
		-- 84. code x55
		"00000000", -- 0
		"00000000", -- 1
		"00010000", -- 2    *
		"00111000", -- 3   ***
		"01101100", -- 4  ** **
		"11000110", -- 5 **   **
		"11000110", -- 6 **   **
		"11000110", -- 7 **   **
		"11111110", -- 8 *******
		"00000000", -- 9
		"00000000", -- a
		"00000000", -- b
--------------------------------------------------------------------------------
		"00000000", -- padding
		"00000000", -- padding
		"00000000", -- padding
		"00000000"  -- padding
	);
begin

	-- addr register to infer block RAM
	setRegA: process (clkA)
	begin
		if rising_edge(clkA) then
			-- Read from it
			dataOutA <= ROM(to_integer(unsigned(addrA)));

		end if;
	end process;
	
end Behavioral;