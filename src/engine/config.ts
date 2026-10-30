import balance from '../data/rebalance.json';
export const rebalance = balance;
/** Parâmetros de protótipo. A edição de regras é fixada por contentVersion. */
export const laboratoryRules = {
 combat: { moto: { defense: 4, integrity: 6, agility: 1 }, hatch: { defense: 4, integrity: 6, agility: 1 }, sedan: { defense: 4, integrity: 8, agility: 0 }, suv: { defense: 3, integrity: 10, agility: 0 }, pickup: { defense: 3, integrity: 10, agility: 0 } },
 defense: 4, territoryIntegrity: 4, attackDamage: 1,
 simpleRepairLimit: 1, simpleRepairCost: 1, simpleRepairAmount: 1,
 complexRepairCost: 2, complexRepairAmount: 4,
 explorationUses: 3, lootQuantity: 2, swapScrap: 3,
 escapeTarget: 5, stealTerritorialCards: true, eventWearDamage: 1,
 raceEnabled: true,
};
export type RuleConfig = typeof laboratoryRules;
