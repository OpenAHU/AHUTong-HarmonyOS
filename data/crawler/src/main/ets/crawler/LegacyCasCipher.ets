const S_BOXES: Array<Array<Array<number>>> = [
  [
    [14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7],
    [0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8],
    [4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0],
    [15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13]
  ],
  [
    [15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10],
    [3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5],
    [0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15],
    [13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9]
  ],
  [
    [10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8],
    [13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1],
    [13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7],
    [1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12]
  ],
  [
    [7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15],
    [13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9],
    [10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4],
    [3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14]
  ],
  [
    [2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9],
    [14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6],
    [4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14],
    [11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3]
  ],
  [
    [12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11],
    [10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8],
    [9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6],
    [4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13]
  ],
  [
    [4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1],
    [13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6],
    [1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2],
    [6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12]
  ],
  [
    [13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7],
    [1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2],
    [7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8],
    [2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11]
  ]
];

const P_PERMUTATION: Array<number> = [
  15, 6, 19, 20, 28, 11, 27, 16, 0, 14, 22, 25, 4, 17, 30, 9,
  1, 7, 23, 13, 31, 26, 2, 8, 18, 12, 29, 5, 21, 10, 3, 24
];

const FINAL_PERMUTATION: Array<number> = [
  39, 7, 47, 15, 55, 23, 63, 31, 38, 6, 46, 14, 54, 22, 62, 30,
  37, 5, 45, 13, 53, 21, 61, 29, 36, 4, 44, 12, 52, 20, 60, 28,
  35, 3, 43, 11, 51, 19, 59, 27, 34, 2, 42, 10, 50, 18, 58, 26,
  33, 1, 41, 9, 49, 17, 57, 25, 32, 0, 40, 8, 48, 16, 56, 24
];

const KEY_PERMUTATION: Array<number> = [
  13, 16, 10, 23, 0, 4, 2, 27, 14, 5, 20, 9, 22, 18, 11, 3,
  25, 7, 15, 6, 26, 19, 12, 1, 40, 51, 30, 36, 46, 54, 29, 39,
  50, 44, 32, 47, 43, 48, 38, 55, 33, 52, 45, 41, 49, 35, 28, 31
];

export class LegacyCasCipher {
  private static stringToBits(value: string): Array<number> {
    const bits: Array<number> = new Array<number>(64).fill(0);
    for (let index = 0; index < Math.min(value.length, 4); index++) {
      const code = value.charCodeAt(index);
      for (let bit = 0; bit < 16; bit++) {
        bits[index * 16 + bit] = (code >> (15 - bit)) & 1;
      }
    }
    return bits;
  }

  private static initialPermutation(input: Array<number>): Array<number> {
    const output: Array<number> = new Array<number>(64).fill(0);
    for (let group = 0, odd = 1, even = 0; group < 4; group++, odd += 2, even += 2) {
      for (let source = 7, target = 0; source >= 0; source--, target++) {
        output[group * 8 + target] = input[source * 8 + odd];
        output[group * 8 + target + 32] = input[source * 8 + even];
      }
    }
    return output;
  }

  private static expand(input: Array<number>): Array<number> {
    const output: Array<number> = new Array<number>(48).fill(0);
    for (let group = 0; group < 8; group++) {
      output[group * 6] = input[group === 0 ? 31 : group * 4 - 1];
      output[group * 6 + 1] = input[group * 4];
      output[group * 6 + 2] = input[group * 4 + 1];
      output[group * 6 + 3] = input[group * 4 + 2];
      output[group * 6 + 4] = input[group * 4 + 3];
      output[group * 6 + 5] = input[group === 7 ? 0 : group * 4 + 4];
    }
    return output;
  }

  private static xor(left: Array<number>, right: Array<number>): Array<number> {
    const output: Array<number> = new Array<number>(left.length).fill(0);
    for (let index = 0; index < left.length; index++) {
      output[index] = left[index] ^ right[index];
    }
    return output;
  }

  private static substitute(input: Array<number>): Array<number> {
    const output: Array<number> = new Array<number>(32).fill(0);
    for (let box = 0; box < 8; box++) {
      const row = input[box * 6] * 2 + input[box * 6 + 5];
      const column = input[box * 6 + 1] * 8 + input[box * 6 + 2] * 4 +
        input[box * 6 + 3] * 2 + input[box * 6 + 4];
      const value = S_BOXES[box][row][column];
      for (let bit = 0; bit < 4; bit++) {
        output[box * 4 + bit] = (value >> (3 - bit)) & 1;
      }
    }
    return output;
  }

  private static permute(input: Array<number>, table: Array<number>): Array<number> {
    const output: Array<number> = new Array<number>(table.length).fill(0);
    for (let index = 0; index < table.length; index++) {
      output[index] = input[table[index]];
    }
    return output;
  }

  private static generateKeys(keyBits: Array<number>): Array<Array<number>> {
    const key: Array<number> = new Array<number>(56).fill(0);
    for (let group = 0; group < 7; group++) {
      for (let target = 0, source = 7; target < 8; target++, source--) {
        key[group * 8 + target] = keyBits[source * 8 + group];
      }
    }

    const shifts: Array<number> = [1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1];
    const keys: Array<Array<number>> = [];
    for (let round = 0; round < 16; round++) {
      for (let shift = 0; shift < shifts[round]; shift++) {
        const left = key[0];
        const right = key[28];
        for (let index = 0; index < 27; index++) {
          key[index] = key[index + 1];
          key[28 + index] = key[29 + index];
        }
        key[27] = left;
        key[55] = right;
      }
      keys.push(LegacyCasCipher.permute(key, KEY_PERMUTATION));
    }
    return keys;
  }

  private static encryptBlock(input: Array<number>, keyBits: Array<number>): Array<number> {
    const keys = LegacyCasCipher.generateKeys(keyBits);
    const initial = LegacyCasCipher.initialPermutation(input);
    let left = initial.slice(0, 32);
    let right = initial.slice(32, 64);
    for (let round = 0; round < 16; round++) {
      const previousLeft = left;
      left = right;
      const expanded = LegacyCasCipher.expand(right);
      const substituted = LegacyCasCipher.substitute(LegacyCasCipher.xor(expanded, keys[round]));
      right = LegacyCasCipher.xor(LegacyCasCipher.permute(substituted, P_PERMUTATION), previousLeft);
    }
    return LegacyCasCipher.permute(right.concat(left), FINAL_PERMUTATION);
  }

  private static bitsToHex(bits: Array<number>): string {
    let output = '';
    for (let index = 0; index < 64; index += 4) {
      const value = bits[index] * 8 + bits[index + 1] * 4 + bits[index + 2] * 2 + bits[index + 3];
      output += value.toString(16).toUpperCase();
    }
    return output;
  }

  static encrypt(value: string): string {
    const keys: Array<Array<number>> = [
      LegacyCasCipher.stringToBits('1'),
      LegacyCasCipher.stringToBits('2'),
      LegacyCasCipher.stringToBits('3')
    ];
    let output = '';
    for (let offset = 0; offset < value.length; offset += 4) {
      let block = LegacyCasCipher.stringToBits(value.substring(offset, offset + 4));
      for (let index = 0; index < keys.length; index++) {
        block = LegacyCasCipher.encryptBlock(block, keys[index]);
      }
      output += LegacyCasCipher.bitsToHex(block);
    }
    return output;
  }
}
