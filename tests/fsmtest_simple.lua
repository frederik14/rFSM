--
-- test simple transitions
--

package.path = package.path .. ';../?.lua'

require("rfsm")
require("fsm2tree")
require("fsmtesting")
require("utils")
require("fsmpp")

cnt = 0

simple_templ = rfsm.csta:new{
   dbg = false, -- fsmpp.dbgcolor,
   on = rfsm.sista:new{},
   off = rfsm.sista:new{},
   busy = rfsm.sista:new{
      doo=function()
	     while cnt < 100000 do
		cnt = cnt + 1
		coroutine.yield()
	     end
	  end
   },

   rfsm.trans:new{ src='initial', tgt='off' },
   rfsm.trans:new{ src='off', tgt='on', events={ 'e_on' } },
   rfsm.trans:new{ src='on', tgt='off', events={ 'e_off' } },
   rfsm.trans:new{ src='off', tgt='busy', events={ 'e_busy' } },
   rfsm.trans:new{ src='busy', tgt='off', events={ 'e_done@root.busy' } },
}


local test = {
   id = 'simple_tests',
   pics = false,
   tests = {
      {
	 descr='testing entry',
	 preact = nil, -- { node=fqn, mode="done" }
	 events = nil,
	 expect = { leaf='root.off', mode='done' },
      }, {
	 descr='testing transition to on',
	 events = { 'e_on' },
	 expect = { leaf='root.on', mode='done'},
      }, {
	 descr='testing transition back to off',
	 events = { 'e_off' },
	 expect = { leaf='root.off', mode='done'},
      }, {
	 descr='testing to busy',
	 events = { 'e_busy' },
	 expect = { leaf='root.busy', mode='done'},
      }, {
	 descr='doing nothing',
	 expect = { leaf='root.off', mode='done'}
      }
   }
}

fsm = rfsm.init(simple_templ, "simple_test")

fsmtesting.print_stats(fsmtesting.test_fsm(fsm, test, false))
