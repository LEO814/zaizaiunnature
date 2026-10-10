# 比赛规则与结算 · 本地 Demo 已编写

PRG-RESULT，程序负责。职责0.3.0、代码/接口0.2.0。controller.lua与公共Session已实现本地时间/撤离/唯一终局，纯Lua仲裁已有离线检查；原生成功撤离、重复终局幂等及手动重开已通过，人工死亡/超时失败流程仍待验。

## 当前实现

模块gameplay.systems.settlement.controller。Settlement.new(context)依赖Session，update(dt)在对象战斗更新之后调用程序内部Session:tick，避免把计时交给UI。close停止推进。

公共状态为LOBBY/EXPLORE/EXTRACTING/FINISHED。默认比赛600秒、撤离3秒；离区或有效受击中断并回EXPLORE，期间比赛时钟继续。死亡优先于超时，超时优先于成功撤离。try_finish校验实际终局条件，重复请求返回同一result_id，不重复发放。

成功结果记录本局带出items/loot_value，失败结果为失败原因/空收益；结束后对象停止攻击/AI/交互，正常新局生成新run_id并清公共状态。QA测试退出使用已有terminal_reason=quit，不扩展固定签名。

## 尚待完整需求

结算持久化、带出物品真正写入仓库/资金、复杂目标规则、多人结果/权限、返回局前与完整商店循环仍待实现。Demo结果页不代表已完成长期经济系统。

## 验收

离线13场景/301断言覆盖死亡/超时/撤离顺序、离区与受击取消、结果唯一性及重开，详见[测试记录](../../../docs/test_results.json)。原生自动QA连续两轮各17项通过，均3秒撤离、带出280并验证重复结算幂等。

手动A/D返回绿区后3秒撤离成功，带出310、结果run_1:result，见[手动撤离](../../../docs/evidence/manual_extraction.png)。普通重开及死亡怪物后的重开均通过单次结果按钮完成，恢复100/60HP、空背包与局次计时/出生点。原生自动QA用Teleport定位；四房完整自然探索、人工死亡/超时和撤离受击取消等边界仍需专项证据。
