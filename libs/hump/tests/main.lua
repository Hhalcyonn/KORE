Timer = require("timer")

function assert_very_close(a, b)
   local tol = 0.0000000001
   assert(math.abs(a - b) < tol,
	  string.format("%.10f is not equal within %.10f of %10f",
			a, tol, b))
end

function test_basic()
   -- test basic functionality
   local basic = {x=0, y=0}
   Timer.tween(3, basic, {x=99, y=66})
   Timer.update(1)
   assert_very_close(basic.x, 33)
   assert_very_close(basic.y, 22)
   Timer.update(2)
   assert_very_close(basic.x, 99)
   assert_very_close(basic.y, 66)
end


function test_tween_userdata()
   -- only run if love is not nil!
   if love ~= nil then
      Timer.func_tween(5, love.graphics, {Color={0, 0, 0}})
      Timer.update(5)
      local r, g, b, a = love.graphics.getColor()
      assert_very_close(r, 0)
      assert_very_close(g, 0)
      assert_very_close(b, 0)
      assert_very_close(a, 1)
   end
end

function test_tween_subtable()
   -- test tweening for sub-table
   local inner_table = {posn={x=20, y=20}}
   Timer.tween(4, inner_table, {posn={x=10, y=30}})
   Timer.update(4)
   assert_very_close(inner_table.posn.x, 10)
   assert_very_close(inner_table.posn.y, 30)
end

function test_tweening_arraylike()
   -- test tweening for array-like
   local array_like = {40, -11}
   Timer.tween(30, array_like, {-10, -10})
   Timer.update(30)
   assert_very_close(array_like[1], -10)
   assert_very_close(array_like[2], -10)
end

function test_tween_setget()
-- -- test tweening for single getter/setter
   univar_setget = {
      getX = function(self)
	 return self.x
      end,
      getY = function(self)
	 return self.y
      end,
      setX = function(self, x)
	 self.x = x
      end,
      setY = function(self, y)
	 self.y = y
      end,
      x = 60,
      y = 60
   }
   Timer.func_tween(5, univar_setget, {X=10, Y=180}, nil, nil, {
		       X={univar_setget.setX, univar_setget.getX},
		       Y={univar_setget.setY, univar_setget.getY}})
   Timer.update(5)
   assert_very_close(univar_setget:getX(), 10)
   assert_very_close(univar_setget:getY(), 180)
end


function test_tweening_multivalue_setget()
   -- test tweening for multi-value getter/setter
   --[[
      Some functions such as `Body:set/getPosition` or `set/getLinearVelocity`
      need and return multiple values
      we should be able to handle that
   --]]
   multivar_setget = {
      getP = function(self)
	 return self.x, self.y
      end,
      setP = function(self, x, y)
	 self.x = x
	 self.y = y
      end,
      x = 80,
      y = 80
   }
   Timer.tween(10, multivar_setget, {P={65, 180}}, 'quad')
   Timer.update(10)
   assert_very_close(multivar_setget.x, 65)
   assert_very_close(multivar_setget.y, 180)
end

function test_tweening_table_setget()
   -- test tweening for table-based getter/setter
   table_setget = {
      getP = function(self)
	 return self.posn
      end,
      setP = function(self, posn)
	 self.posn.x = posn.x
	 self.posn.y = posn.y
      end,
      posn={x=100, y=100}
   }
   Timer.tween(10, table_setget, {P={x=65, y=180}}, 'quad')
   Timer.update(10)
   assert_very_close(table_setget.posn.x, 65)
   assert_very_close(table_setget.posn.y, 180)

end

function test_tweening_arraylike_table_setget()
-- test tweening setget for array-like tables
   array_setget = {
      getP = function(self)
	 return self.posn
      end,
      setP = function(self, posn)
	 self.posn=posn
      end,
      posn = {120, 120}
   }

   Timer.tween(10, array_setget, {P={65, 180}}, 'quad')
   Timer.update(10)
   assert_very_close(array_setget.posn[1], 65)
   assert_very_close(array_setget.posn[2], 180)
end

function runtests()
   print("run tests")
   for n, t in pairs(_G) do
      if string.find(n, 'test_') then
	 local s, e =  pcall(t)
	 if s then print("PASS")
	 else print('error in ', n, ":") print(e) end
      end
   end
end
	    
	 
if love ~= nil then
   function love.load()
      runtests()
   end
else
   runtests()
end
   
