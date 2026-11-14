import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity('technical_condition')
export class TechnicalCondition {
  @PrimaryGeneratedColumn({ type: 'bigint' })
  id!: string;

  @Column({
    type: 'varchar',
    length: 20,
    charset: 'ascii',
    collation: 'ascii_bin',
    unique: true,
  })
  code!: string;

  @Column({ type: 'varchar', length: 255, unique: true })
  name!: string;

  @Column({ name: 'is_active', type: 'tinyint', default: 1 })
  isActive!: number;
}
