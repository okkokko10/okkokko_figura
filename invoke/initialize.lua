
require"invoke.Invoke"

local Writing = require"./Writing"

local Text = Writing.makeVirtual()


Text:newLine'global'
Text:newLine'invoke okkokko {gsub={p="^%s*>>>(.*)",r="invokeX okkokko %1"}}'
Text:newLine';invoke okkokko {gsub={p="^%s*>>(.*)",r="invoke okkokko {%1}"}}'
Text:newLine';>> gsub ={ p="<[|:](.*)$", r="={ %1 }",rec=true}'
Text:newLine';>> gsub ={ p="%-%>", r="]["}'

Text:newLine'>>>[text.initialization started] log'


Text:newLine'>>>fun.lentc: ite([args[var!SelectedRow][var!key] -> equal]){text.#000000} O(get.v) entitycolor'
-- Text:newLine'>>>fun.lentt: formats.${get.p} ${[O(get.v) S]} ${[]} | ${Nl}'
Text:newLine'>>>fun.lentt: formats.${get.p} (${get.c}) ${O(get.v) S}${Nl}'


Text:newLine'>>>fun.display_entity_list_f: [M[Array{text=[run.lentt] color=[run.lentc]}] ]J'
Text:newLine'>>>fun.display_entity_list:O(var.ent)[run.display_entity_list_f][say]'


Text:newLine'>>>fun.gitems:Array[method.getItem 1][method.getItem 2][method.getItem 3][method.getItem 4][method.getItem 5]'
Text:newLine'>>>fun.entin: I(Lo) formats.${method.getName}${Nl} ${[call.gitems][M S][concat.  \']}'

Text:newLine'>>>fun.targetline:[ args[text.SpareLineStart][][] ] affix'

Text:newLine'>>>fun.init_ent:set.ent:[Entities -> grch[formats.${method.getType} : ${method.getName}] -> sort[get.p]]'
Text:newLine'>>>fun.U_update_ent_selection:O(var.ent) [args[][var!SelectedRow] -> getkv -> O()[E run.targetline:set.slg:[get.v][I(Lo)]] [I(on.offhand) [get.l][set.ent:grch[method.getPos -> S]]]]'
Text:newLine'>>>fun.U_update_ent: [E IT(on.sneak) run.init_ent] [E run.U_update_ent_selection]'
-- Text:newLine'>>>fun.show_ent:O(var.ent)[M Array{text=[run.lentt] color=[run.lentc]} -> J -> say]'
Text:newLine'>>>[text.initialization ended] log'
Text:newLine''
Text:newLine''
Text:newLine''



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
        Invoke.contents(Invoke.newInstance(Text,initializer_player))
        -- log("initialized invoke")
        -- events.ENTITY_INIT:remove("InvokeInitialize")
    end,"InvokeInitialize")

end
