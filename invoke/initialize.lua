
require"invoke.Invoke"

local Writing = require"./Writing"

local Text = Writing.makeVirtual()


Text:newLine'global'
Text:newLine'invoke okkokko {gsub={p="^%s*>>>(.*)",r="invokeX okkokko %1"}}'
-- Text:newLine';invoke okkokko {gsub={p="^%s*>>(.*)",r="invoke okkokko {%1}"}}'
-- Text:newLine';>> gsub ={ p="<[|:](.*)$", r="={ %1 }",rec=true}'
Text:newLine';invoke okkokko {gsub ={ p="%-%>", r="]["}}'

-- Text:newLine'>>>[text.initialization started] log'

--- maps 0..1 to red..green
Text:newLine'>>>fun.safecolor:[args(lerp)[fromHex.RED][fromHex.GREEN][]] rgb'

Text:newLine'>>>fun.safecolorOf:[args(div)[get.1][get.2]] run.safecolor'
Text:newLine'>>>fun.safecolorOfComp:[args(div)[get.1][get.2]][complement] run.safecolor'

Text:newLine'>>>fun.item_status_small: [method.getNbt]'
'I(get.Age) I(get.Lifespan)'
'[Array{text=[formats.${[get.Age] S}/${[get.Lifespan] S} age] color=[args(run.safecolorOfComp)[get.Age][get.Lifespan]]}] J '

Text:newLine'>>>fun.item_age: [method.getNbt]'
'I(get.Age) I(get.Lifespan)'
'formats.${[args(fdiv)[args(minus)[get.Lifespan][get.Age]][const 20]] S}s'

Text:newLine'>>>fun.entity_status_hp: formats.${[call?getHealth] S}/${[call?getMaxHealth] S}HP'

Text:newLine'>>>fun.entity_status_small:ite(args(equal)[call?getType][text.minecraft:item]){run.item_age} run.entity_status_hp'


Text:newLine'>>>fun.lentc: ite([args[var!SelectedRow][var!key] -> equal]){text.#000000} O(get.v) entitycolor'
-- Text:newLine'>>>fun.lentt: formats.${get.p} ${[O(get.v) S]} ${[]} | ${Nl}'
Text:newLine'>>>fun.lentt: formats.${get.p} (${get.c}) ${O(get.v) run.entity_status_small} ${Nl}'


Text:newLine'>>>fun.display_entity_list_f: [M[Array{text=[run.lentt] color=[run.lentc]}] ]J'
Text:newLine'>>>fun.display_entity_list:O(var.ent)[run.display_entity_list_f][say]'

Text:newLine'>>>fun.arrayDisp: [keyvalue]   M Array[get.k][text : ][ [get.v] J ][Nl]  '



Text:newLine'>>>fun.gitems:Array[method.getItem 1][method.getItem 2][method.getItem 3][method.getItem 4][method.getItem 5]'
Text:newLine'>>>fun.entin: I(Lo) formats.${method.getName}\n${[run.gitems][M [method.getName]][concat.\n]}'
Text:newLine'>>>fun.second_disp:O(var.slg)[run.entin] S'


Text:newLine
'>>>fun.display_entity_list_two:'
'['
    'formats['
    '"",'
    '${O(var.ent)[run.display_entity_list_f]}'
    ',"${Nl}",'
    '"${run.second_disp}",'
    '"\n",'
    '${[O(var.slg) I(Lo) O(method.getNbt) [run.arrayDisp] J ] D text""}'
    '] '
']'
'say.left'
-- todo: a string formatter that automatically does this.



Text:newLine'>>>fun.targetline:[ args[text.SpareLineStart][][] ] affix'
Text:newLine'>>>fun.targetlines:[ args[text.SpareLineStart][] ] affixM'

Text:newLine'>>>fun.init_ent:set.ent:[Entities -> grch[formats.${method.getType} : ${method.getName}] -> sort[get.p]]'
-- Text:newLine'>>>fun.U_update_ent_selection:O(var.ent) [args[][var!SelectedRow] -> getkv -> O()[E run.targetline:set.slg:[get.v]I(Lo)] [I(on.offhand) [get.l][set.ent:grch[method.getPos -> S]]]]'
Text:newLine'>>>fun.selection_slg:[E set.slg:[get.v]I(Lo)]'
Text:newLine'>>>fun.selection_lines:[E O(get.l)[M I(Lo)] run.targetlines]'
Text:newLine'>>>fun.selection_specify:[get.l][set.ent:grch[method.getPos -> S]]'
Text:newLine'>>>fun.U_update_ent_selection:O(var.ent) [args(getkv)[][var!SelectedRow] ] O() [E run.selection_slg] [E run.selection_lines] [I(on.offhand) run.selection_specify]'
Text:newLine'>>>fun.U_update_ent: [E I(on.sneak) run.init_ent] [E run.U_update_ent_selection]'
Text:newLine'>>>fun.U_update_ent_constantly: [E run.init_ent] [E run.U_update_ent_selection]'
-- Text:newLine'>>>fun.show_ent:O(var.ent)[M Array{text=[run.lentt] color=[run.lentc]} -> J -> say]'

-- Text:newLine'fun.blockDataBlacklist: O(method.getEntityData)  '


Text:newLine'>>>fun.blockDataDisplay: O(method.getEntityData) O(get.BlockEntityTag) [run.arrayDisp] J'

Text:newLine
'>>>fun.checkedBlockDisplay: O(method.getEntityData) O(get.BlockEntityTag) [E set.checkedBlockTags] [E M [var!key] assign.checkedBlockKeys]'
'[var.checkedBlockKeys] [M Od( args(getkv)[var.checkedBlockTags][var!key] ) False ]'
' [keyvalue] [  M Array[get.k][text : ] [ [get.v] ite(){J} text ][Nl]  ] J'
Text:newLine'>>>fun.checkBlock: [I(on.sneak) [set.checkedBlock:[User]PickBlock]] [D [text] say] set.checkedBlockKeys:Array{}'
Text:newLine'>>>fun.checkBlockVisF:O(var.checkedBlock) [run.checkedBlockDisplay] say.left'

Text:newLine'>>>fun.checkBlockVis:fun!AlwaysActive:run.checkBlockVisF'

Text:newLine''
Text:newLine''


-- Text:newLine'>>>fun.trackMatching'

Text:newLine
'>>>fun.EntityDisplayData:' 
--'log'
-- 'run.entity_status'
'f["",${I(Lo) O(method.getNbt) [run.arrayDisp] J}]'



Text:newLine'>>>fun.DisplayDataEntity:'
'['
    'args(display)'
        '['
            '[Track.eyes] child.BILLBOARD '
        ']'
        '[run.EntityDisplayData]'
']' 
'method.setPos -16, 0, 0'

Text:newLine'>>>fun.DisplayDataEntities:[Entities] M run.DisplayDataEntity'


Text:newLine'>>>fun.TrailEntities:'
'['
    '[Entities] M args(Trail)[Track][method.getPos]'
']' 
Text:newLine'>>>fun.TrailArrows:'
'[E ite(var.flipTrArCol){[nil] set.flipTrArCol} [text#FF8800] set.flipTrArCol]'
'['
    '[Entities] M I(args(equal)[method.getType][text.minecraft:arrow])' 
        'args(Trail)[Track][method.getPos][var.flipTrArCol][O(method.getNbt) [get.Motion] vec]'
']' 

Text:newLine'>>>fun.ClearTrailEntities:'
'['
    '[Entities] M args(Trail.clear)[Track]'
']' 


Text:newLine'>>>[text.initialization ended] log'
Text:newLine''
Text:newLine''
Text:newLine''
Text:newLine''
Text:newLine''

-- Text:newLine'>>>[IT([var.vendors] notn) [newmutable] [E set.vendors] log];'



-- Text:newLine'>>> fun.displayvendors:[var.vendors -> Keys -> sort -> J -> say];'
-- Text:newLine('>>> fun.processvendor: IT(O() [method.getID -> eq.\'numismatics:vendor\']) ['..
--     'formats ${[method.getEntityData -> formats ${[get.Selling.id -> E set.idtest__ -> S]} (${[get.Selling.count -> S]}) ${O(get.Prices) pricestring}]} ${[method.getPos -> S]}${Nl}->'..
--     'IT(var.idtest__) E assign.vendors]')
-- Text:newLine'>>> fun.userarea: [User -> method.getPos -> area 20]'
-- Text:newLine'>>>fun.scanvendors:[ run.userarea -> Scan{[run.processvendor] nil}{}]'
-- Text:newLine'>>>fun.scan_this_vendor:IT(on.sneak)  O([User] PickBlock) [run.processvendor -> O() say]'
-- Text:newLine''
-- Text:newLine''
-- Text:newLine'>>>[text.initialization ended 2] log'

-- Text:newLine
-- '>>>[text{"text":"","extra":["<",{"text":"","extra":[{"text":"","extra":["okkokko"," ",{"text":"△","hoverEvent":{"contents":{"translate":"figura.badges.system.default"},"action":"show_text"},"font":"figura:badges","obfuscated":false,"color":"#5555FF"}]}],"hoverEvent":{"contents":{"type":"minecraft:player","id":[1341784454,953436005,-1716287089,339402456],"name":"okkokko"},"action":"show_entity"},"insertion":"okkokko","clickEvent":{"action":"suggest_command","value":"/tell okkokko "}},"> ",{"text":"","hoverEvent":{"contents":{"text":":heart:","extra":["\n",{"translate":"figura.emoji.heart","color":"dark_gray"}]},"action":"show_text"},"font":"figura:emoji_heart","color":"white"}]}] [E say] log'

-- {"text":"","extra":["<",{"text":"","extra":[{"text":"","extra":["okkokko"," ",{"text":"△","hoverEvent":{"contents":{"translate":"figura.badges.system.default"},"action":"show_text"},"font":"figura:badges","obfuscated":false,"color":"#5555FF"}]}],"hoverEvent":{"contents":{"type":"minecraft:player","id":[1341784454,953436005,-1716287089,339402456],"name":"okkokko"},"action":"show_entity"},"insertion":"okkokko","clickEvent":{"action":"suggest_command","value":"/tell okkokko "}},"> ",{"text":"","hoverEvent":{"contents":{"text":":heart:","extra":["\n",{"translate":"figura.emoji.heart","color":"dark_gray"}]},"action":"show_text"},"font":"figura:emoji_heart","color":"white"}]}


local initializer_player = {
}
function initializer_player:getUUID()
    return "initializer"
end
function initializer_player:isLoaded()
    return true
end



if Invoke.ENABLE and (avatar:getPermissionLevel() == "MAX" or Invoke.LOWER_PERMISSION) and (host:isHost() or Invoke.ENABLE_OTHERS)  then
    
    events.ENTITY_INIT:register(function ()
        Invoke.ambient = Invoke.newInstance(Text,initializer_player)
        Invoke.ambient:contents()
        -- log("initialized invoke")
        -- events.ENTITY_INIT:remove("InvokeInitialize")
    end,"InvokeInitialize")

end
