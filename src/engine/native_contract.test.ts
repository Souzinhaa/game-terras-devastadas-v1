import { afterAll, expect, it } from 'vitest';
import { mkdirSync, writeFileSync } from 'node:fs';
import fixtures from '../../godot/tests/shared_contracts.json';
import { createGame, points, transition } from './game';

const report: Record<string, unknown> = {};
for (const fixture of fixtures) {
  it(`contrato compartilhado Godot/TS: ${fixture.name}`, () => {
    let state = createGame(['A', 'B'], 42);
    state.started = true;
    const player = state.players[state.active];
    if (fixture.name === 'moto_upgrade') {
      player.vehicle.integrity = 3;
      for (const territory of Object.values(state.territories)) {
        if (territory.owner === player.id && territory.city === player.city) territory.stock.scrap = 4;
      }
      state = transition(state, { type: 'upgradeVehicle', modelId: 'moto' });
    } else if (fixture.name === 'sedan_repair') {
      player.vehicle.modelId = 'sedan';
      player.vehicle.fixedEquipmentId = 'fixed-sedan';
      player.vehicle.integrity = 7;
      state = transition(state, { type: 'repair', complex: false });
    } else {
      for (const territory of Object.values(state.territories)) territory.owner = player.id;
    }
    const p = state.players[state.active];
    const result = fixture.name === 'all_cities' ? { points: points(state, p.id) } : {
      model: p.vehicle.modelId, integrity: p.vehicle.integrity, fuel: p.vehicle.fuelUnits,
      scrap: p.stock.scrap, actions: state.actions, deaths: p.deaths,
    };
    report[fixture.name] = result;
    expect(result).toEqual(fixture.expected);
  });
}
afterAll(() => {
  mkdirSync('.tools', { recursive: true });
  writeFileSync('.tools/ts-contracts.json', JSON.stringify(report));
});
