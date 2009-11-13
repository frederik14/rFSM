#!/usr/bin/lua

require('gv')
require('fsmutils')

local pairs, ipairs, print, table, type, assert, gv, io, fsmutils
   = pairs, ipairs, print, table, type, assert, gv, io, fsmutils

module("fsm2tree")

param = {}

param.trfontsize = 7.0
param.show_fqn = false
param.and_color="green"
param.and_style="dashed"
param.hedge_color="blue"
param.hedge_style="dotted"

param.layout="dot"
param.dbg=print
param.err=print


-- overall state properties

local function set_sprops(nh)
   gv.setv(nh, "style", "rounded")
   gv.setv(nh, "shape", "box")
end

local function set_ini_sprops(nh)
   gv.setv(nh, "shape", "point")
   gv.setv(nh, "height", "0.15")
end

local function set_fini_sprops(nh)
   gv.setv(nh, "shape", "doublecircle")
   gv.setv(nh, "label", "")
   gv.setv(nh, "height", "0.1")
end

local function set_hier_trans_props(eh)
   gv.setv(eh, "arrowhead", "none")
   gv.setv(eh, "style", param.hedge_style)
   gv.setv(eh, "color", param.hedge_color)
end

local function set_trans_props(eh)
   gv.setv(eh, "fontsize", param.trfontsize)
end

-- create new graph and add root node
local function new_graph(fsm)
   local gh = gv.digraph("hierarchical chart: " .. fsm.id)
   gv.setv(gh, "rankdir", "TD")

   local nh = gv.node(gh, fsm.fqn)
   set_sprops(nh)

   return gh
end

-- add regular type of state
local function add_state(gh, parent, state)

   local nh = gv.node(gh, state.fqn)
   set_sprops(nh)

   local eh = gv.edge(gh, parent.fqn, state.fqn)
   set_hier_trans_props(eh)

   -- if we're part of a parallel state change color of hier_trans
   if parent.parallel then
      gv.setv(eh, "color", param.and_color)
      gv.setv(eh, "style", param.and_style)
   end

   if not param.show_fqn then
      gv.setv(nh, "label", state.id)
   end
end

-- add initial states
local function add_ini_state(gh, tr, parent)
   local nh, eh
   if tr.src == 'initial' then
      nh = gv.node(gh, parent.fqn .. '.initial')
      set_ini_sprops(nh)
      eh = gv.edge(gh, parent.fqn, parent.fqn .. '.initial')
      set_hier_trans_props(eh)
   end
end

-- add  final states
local function add_fini_state(gh, tr, parent)
   local nh, eh
   if tr.tgt == 'final' then
      nh = gv.node(gh, parent.fqn .. '.final')
      set_fini_sprops(nh)
      eh = gv.edge(gh, parent.fqn, parent.fqn .. '.final')
      set_hier_trans_props(eh)
   end
end


-- add a transition from src to tgt
local function add_trans(gh, tr, parent)
   local src, tgt, eh

   if tr.src == 'initial' then src = parent.fqn .. '.initial'
   else src = tr.src.fqn end

   if tr.tgt == 'final' then tgt = parent.fqn .. '.final'
   else tgt = tr.tgt.fqn end

   eh = gv.edge(gh, src, tgt)
   gv.setv(eh, "constraint", "false")
   if tr.event then gv.setv(eh, "label", tr.event) end
   set_trans_props(eh)
end

local function fsm2gh(fsm)
   local gh = new_graph(fsm)
   fsmutils.map_trans(function (tr, p) add_ini_state(gh, tr, p) end, fsm)
   fsmutils.map_state(function (s) add_state(gh, s.parent, s) end, fsm)
   fsmutils.map_trans(function (tr, p) add_fini_state(gh, tr, p) end, fsm)

   fsmutils.map_trans(function (tr, p) add_trans(gh, tr, p) end, fsm)
   return gh
end


-- convert fsm to 
function fsm2img(fsm, format, outfile)

   if not fsm.__initalized then
      param.err("fsm2tree ERROR: fsm " .. fsm.id .. " uninitialized")
      return false
   end

   local gh = fsm2gh(fsm)
   gv.layout(gh, param.layout)
   param.dbg("fsm2tree: running " .. param.layout .. " layouter")
   gv.render(gh, format, outfile)
   param.dbg("fsm2tree: rendering to " .. format .. ", written result to " .. outfile)
end