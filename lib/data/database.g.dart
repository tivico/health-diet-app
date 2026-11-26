// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Sex, int> sex =
      GeneratedColumn<int>(
        'sex',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Sex>($UserProfilesTable.$convertersex);
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ActivityLevel, int> activity =
      GeneratedColumn<int>(
        'activity',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ActivityLevel>($UserProfilesTable.$converteractivity);
  @override
  late final GeneratedColumnWithTypeConverter<Goal, int> goal =
      GeneratedColumn<int>(
        'goal',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Goal>($UserProfilesTable.$convertergoal);
  static const VerificationMeta _bodyFatPctMeta = const VerificationMeta(
    'bodyFatPct',
  );
  @override
  late final GeneratedColumn<double> bodyFatPct = GeneratedColumn<double>(
    'body_fat_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetWeightKgMeta = const VerificationMeta(
    'targetWeightKg',
  );
  @override
  late final GeneratedColumn<double> targetWeightKg = GeneratedColumn<double>(
    'target_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sex,
    age,
    heightCm,
    weightKg,
    activity,
    goal,
    bodyFatPct,
    targetWeightKg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    } else if (isInserting) {
      context.missing(_ageMeta);
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    } else if (isInserting) {
      context.missing(_heightCmMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('body_fat_pct')) {
      context.handle(
        _bodyFatPctMeta,
        bodyFatPct.isAcceptableOrUnknown(
          data['body_fat_pct']!,
          _bodyFatPctMeta,
        ),
      );
    }
    if (data.containsKey('target_weight_kg')) {
      context.handle(
        _targetWeightKgMeta,
        targetWeightKg.isAcceptableOrUnknown(
          data['target_weight_kg']!,
          _targetWeightKgMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sex: $UserProfilesTable.$convertersex.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sex'],
        )!,
      ),
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      )!,
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      activity: $UserProfilesTable.$converteractivity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}activity'],
        )!,
      ),
      goal: $UserProfilesTable.$convertergoal.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}goal'],
        )!,
      ),
      bodyFatPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_pct'],
      ),
      targetWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_weight_kg'],
      ),
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Sex, int, int> $convertersex =
      const EnumIndexConverter<Sex>(Sex.values);
  static JsonTypeConverter2<ActivityLevel, int, int> $converteractivity =
      const EnumIndexConverter<ActivityLevel>(ActivityLevel.values);
  static JsonTypeConverter2<Goal, int, int> $convertergoal =
      const EnumIndexConverter<Goal>(Goal.values);
}

class UserProfileRow extends DataClass implements Insertable<UserProfileRow> {
  final int id;
  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final Goal goal;
  final double? bodyFatPct;

  /// 目標體重（v3 加入）。nullable：沒設定目標的人不該被硬塞一個數字。
  final double? targetWeightKg;
  const UserProfileRow({
    required this.id,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    this.bodyFatPct,
    this.targetWeightKg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['sex'] = Variable<int>($UserProfilesTable.$convertersex.toSql(sex));
    }
    map['age'] = Variable<int>(age);
    map['height_cm'] = Variable<double>(heightCm);
    map['weight_kg'] = Variable<double>(weightKg);
    {
      map['activity'] = Variable<int>(
        $UserProfilesTable.$converteractivity.toSql(activity),
      );
    }
    {
      map['goal'] = Variable<int>(
        $UserProfilesTable.$convertergoal.toSql(goal),
      );
    }
    if (!nullToAbsent || bodyFatPct != null) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct);
    }
    if (!nullToAbsent || targetWeightKg != null) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg);
    }
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      sex: Value(sex),
      age: Value(age),
      heightCm: Value(heightCm),
      weightKg: Value(weightKg),
      activity: Value(activity),
      goal: Value(goal),
      bodyFatPct: bodyFatPct == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPct),
      targetWeightKg: targetWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeightKg),
    );
  }

  factory UserProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileRow(
      id: serializer.fromJson<int>(json['id']),
      sex: $UserProfilesTable.$convertersex.fromJson(
        serializer.fromJson<int>(json['sex']),
      ),
      age: serializer.fromJson<int>(json['age']),
      heightCm: serializer.fromJson<double>(json['heightCm']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      activity: $UserProfilesTable.$converteractivity.fromJson(
        serializer.fromJson<int>(json['activity']),
      ),
      goal: $UserProfilesTable.$convertergoal.fromJson(
        serializer.fromJson<int>(json['goal']),
      ),
      bodyFatPct: serializer.fromJson<double?>(json['bodyFatPct']),
      targetWeightKg: serializer.fromJson<double?>(json['targetWeightKg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sex': serializer.toJson<int>(
        $UserProfilesTable.$convertersex.toJson(sex),
      ),
      'age': serializer.toJson<int>(age),
      'heightCm': serializer.toJson<double>(heightCm),
      'weightKg': serializer.toJson<double>(weightKg),
      'activity': serializer.toJson<int>(
        $UserProfilesTable.$converteractivity.toJson(activity),
      ),
      'goal': serializer.toJson<int>(
        $UserProfilesTable.$convertergoal.toJson(goal),
      ),
      'bodyFatPct': serializer.toJson<double?>(bodyFatPct),
      'targetWeightKg': serializer.toJson<double?>(targetWeightKg),
    };
  }

  UserProfileRow copyWith({
    int? id,
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    Goal? goal,
    Value<double?> bodyFatPct = const Value.absent(),
    Value<double?> targetWeightKg = const Value.absent(),
  }) => UserProfileRow(
    id: id ?? this.id,
    sex: sex ?? this.sex,
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    activity: activity ?? this.activity,
    goal: goal ?? this.goal,
    bodyFatPct: bodyFatPct.present ? bodyFatPct.value : this.bodyFatPct,
    targetWeightKg: targetWeightKg.present
        ? targetWeightKg.value
        : this.targetWeightKg,
  );
  UserProfileRow copyWithCompanion(UserProfilesCompanion data) {
    return UserProfileRow(
      id: data.id.present ? data.id.value : this.id,
      sex: data.sex.present ? data.sex.value : this.sex,
      age: data.age.present ? data.age.value : this.age,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      activity: data.activity.present ? data.activity.value : this.activity,
      goal: data.goal.present ? data.goal.value : this.goal,
      bodyFatPct: data.bodyFatPct.present
          ? data.bodyFatPct.value
          : this.bodyFatPct,
      targetWeightKg: data.targetWeightKg.present
          ? data.targetWeightKg.value
          : this.targetWeightKg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileRow(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('activity: $activity, ')
          ..write('goal: $goal, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('targetWeightKg: $targetWeightKg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sex,
    age,
    heightCm,
    weightKg,
    activity,
    goal,
    bodyFatPct,
    targetWeightKg,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileRow &&
          other.id == this.id &&
          other.sex == this.sex &&
          other.age == this.age &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.activity == this.activity &&
          other.goal == this.goal &&
          other.bodyFatPct == this.bodyFatPct &&
          other.targetWeightKg == this.targetWeightKg);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfileRow> {
  final Value<int> id;
  final Value<Sex> sex;
  final Value<int> age;
  final Value<double> heightCm;
  final Value<double> weightKg;
  final Value<ActivityLevel> activity;
  final Value<Goal> goal;
  final Value<double?> bodyFatPct;
  final Value<double?> targetWeightKg;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.sex = const Value.absent(),
    this.age = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.activity = const Value.absent(),
    this.goal = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    required Sex sex,
    required int age,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activity,
    required Goal goal,
    this.bodyFatPct = const Value.absent(),
    this.targetWeightKg = const Value.absent(),
  }) : sex = Value(sex),
       age = Value(age),
       heightCm = Value(heightCm),
       weightKg = Value(weightKg),
       activity = Value(activity),
       goal = Value(goal);
  static Insertable<UserProfileRow> custom({
    Expression<int>? id,
    Expression<int>? sex,
    Expression<int>? age,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<int>? activity,
    Expression<int>? goal,
    Expression<double>? bodyFatPct,
    Expression<double>? targetWeightKg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sex != null) 'sex': sex,
      if (age != null) 'age': age,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (activity != null) 'activity': activity,
      if (goal != null) 'goal': goal,
      if (bodyFatPct != null) 'body_fat_pct': bodyFatPct,
      if (targetWeightKg != null) 'target_weight_kg': targetWeightKg,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<Sex>? sex,
    Value<int>? age,
    Value<double>? heightCm,
    Value<double>? weightKg,
    Value<ActivityLevel>? activity,
    Value<Goal>? goal,
    Value<double?>? bodyFatPct,
    Value<double?>? targetWeightKg,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sex.present) {
      map['sex'] = Variable<int>(
        $UserProfilesTable.$convertersex.toSql(sex.value),
      );
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (activity.present) {
      map['activity'] = Variable<int>(
        $UserProfilesTable.$converteractivity.toSql(activity.value),
      );
    }
    if (goal.present) {
      map['goal'] = Variable<int>(
        $UserProfilesTable.$convertergoal.toSql(goal.value),
      );
    }
    if (bodyFatPct.present) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct.value);
    }
    if (targetWeightKg.present) {
      map['target_weight_kg'] = Variable<double>(targetWeightKg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('sex: $sex, ')
          ..write('age: $age, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('activity: $activity, ')
          ..write('goal: $goal, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('targetWeightKg: $targetWeightKg')
          ..write(')'))
        .toString();
  }
}

class $MealEntriesTable extends MealEntries
    with TableInfo<$MealEntriesTable, MealEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eatenAtMeta = const VerificationMeta(
    'eatenAt',
  );
  @override
  late final GeneratedColumn<DateTime> eatenAt = GeneratedColumn<DateTime>(
    'eaten_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _caloriesMeta = const VerificationMeta(
    'calories',
  );
  @override
  late final GeneratedColumn<double> calories = GeneratedColumn<double>(
    'calories',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MealType?, int> mealType =
      GeneratedColumn<int>(
        'meal_type',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<MealType?>($MealEntriesTable.$convertermealTypen);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eatenAt,
    name,
    calories,
    proteinG,
    fatG,
    carbsG,
    mealType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('eaten_at')) {
      context.handle(
        _eatenAtMeta,
        eatenAt.isAcceptableOrUnknown(data['eaten_at']!, _eatenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_eatenAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('calories')) {
      context.handle(
        _caloriesMeta,
        calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta),
      );
    } else if (isInserting) {
      context.missing(_caloriesMeta);
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    } else if (isInserting) {
      context.missing(_proteinGMeta);
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    } else if (isInserting) {
      context.missing(_fatGMeta);
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    } else if (isInserting) {
      context.missing(_carbsGMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eatenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}eaten_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      calories: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calories'],
      )!,
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      )!,
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      )!,
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      )!,
      mealType: $MealEntriesTable.$convertermealTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}meal_type'],
        ),
      ),
    );
  }

  @override
  $MealEntriesTable createAlias(String alias) {
    return $MealEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealType, int, int> $convertermealType =
      const EnumIndexConverter<MealType>(MealType.values);
  static JsonTypeConverter2<MealType?, int?, int?> $convertermealTypen =
      JsonTypeConverter2.asNullable($convertermealType);
}

class MealEntry extends DataClass implements Insertable<MealEntry> {
  final int id;
  final DateTime eatenAt;
  final String name;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;

  /// 餐別（v2 加入）。nullable：v1 時期記的餐點本來就沒有這個資訊，
  /// 硬塞預設值等於偽造資料，所以留 null 顯示為「未分類」。
  final MealType? mealType;
  const MealEntry({
    required this.id,
    required this.eatenAt,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    this.mealType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['eaten_at'] = Variable<DateTime>(eatenAt);
    map['name'] = Variable<String>(name);
    map['calories'] = Variable<double>(calories);
    map['protein_g'] = Variable<double>(proteinG);
    map['fat_g'] = Variable<double>(fatG);
    map['carbs_g'] = Variable<double>(carbsG);
    if (!nullToAbsent || mealType != null) {
      map['meal_type'] = Variable<int>(
        $MealEntriesTable.$convertermealTypen.toSql(mealType),
      );
    }
    return map;
  }

  MealEntriesCompanion toCompanion(bool nullToAbsent) {
    return MealEntriesCompanion(
      id: Value(id),
      eatenAt: Value(eatenAt),
      name: Value(name),
      calories: Value(calories),
      proteinG: Value(proteinG),
      fatG: Value(fatG),
      carbsG: Value(carbsG),
      mealType: mealType == null && nullToAbsent
          ? const Value.absent()
          : Value(mealType),
    );
  }

  factory MealEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealEntry(
      id: serializer.fromJson<int>(json['id']),
      eatenAt: serializer.fromJson<DateTime>(json['eatenAt']),
      name: serializer.fromJson<String>(json['name']),
      calories: serializer.fromJson<double>(json['calories']),
      proteinG: serializer.fromJson<double>(json['proteinG']),
      fatG: serializer.fromJson<double>(json['fatG']),
      carbsG: serializer.fromJson<double>(json['carbsG']),
      mealType: $MealEntriesTable.$convertermealTypen.fromJson(
        serializer.fromJson<int?>(json['mealType']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eatenAt': serializer.toJson<DateTime>(eatenAt),
      'name': serializer.toJson<String>(name),
      'calories': serializer.toJson<double>(calories),
      'proteinG': serializer.toJson<double>(proteinG),
      'fatG': serializer.toJson<double>(fatG),
      'carbsG': serializer.toJson<double>(carbsG),
      'mealType': serializer.toJson<int?>(
        $MealEntriesTable.$convertermealTypen.toJson(mealType),
      ),
    };
  }

  MealEntry copyWith({
    int? id,
    DateTime? eatenAt,
    String? name,
    double? calories,
    double? proteinG,
    double? fatG,
    double? carbsG,
    Value<MealType?> mealType = const Value.absent(),
  }) => MealEntry(
    id: id ?? this.id,
    eatenAt: eatenAt ?? this.eatenAt,
    name: name ?? this.name,
    calories: calories ?? this.calories,
    proteinG: proteinG ?? this.proteinG,
    fatG: fatG ?? this.fatG,
    carbsG: carbsG ?? this.carbsG,
    mealType: mealType.present ? mealType.value : this.mealType,
  );
  MealEntry copyWithCompanion(MealEntriesCompanion data) {
    return MealEntry(
      id: data.id.present ? data.id.value : this.id,
      eatenAt: data.eatenAt.present ? data.eatenAt.value : this.eatenAt,
      name: data.name.present ? data.name.value : this.name,
      calories: data.calories.present ? data.calories.value : this.calories,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      mealType: data.mealType.present ? data.mealType.value : this.mealType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealEntry(')
          ..write('id: $id, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('name: $name, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbsG: $carbsG, ')
          ..write('mealType: $mealType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eatenAt,
    name,
    calories,
    proteinG,
    fatG,
    carbsG,
    mealType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealEntry &&
          other.id == this.id &&
          other.eatenAt == this.eatenAt &&
          other.name == this.name &&
          other.calories == this.calories &&
          other.proteinG == this.proteinG &&
          other.fatG == this.fatG &&
          other.carbsG == this.carbsG &&
          other.mealType == this.mealType);
}

class MealEntriesCompanion extends UpdateCompanion<MealEntry> {
  final Value<int> id;
  final Value<DateTime> eatenAt;
  final Value<String> name;
  final Value<double> calories;
  final Value<double> proteinG;
  final Value<double> fatG;
  final Value<double> carbsG;
  final Value<MealType?> mealType;
  const MealEntriesCompanion({
    this.id = const Value.absent(),
    this.eatenAt = const Value.absent(),
    this.name = const Value.absent(),
    this.calories = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.mealType = const Value.absent(),
  });
  MealEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime eatenAt,
    required String name,
    required double calories,
    required double proteinG,
    required double fatG,
    required double carbsG,
    this.mealType = const Value.absent(),
  }) : eatenAt = Value(eatenAt),
       name = Value(name),
       calories = Value(calories),
       proteinG = Value(proteinG),
       fatG = Value(fatG),
       carbsG = Value(carbsG);
  static Insertable<MealEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? eatenAt,
    Expression<String>? name,
    Expression<double>? calories,
    Expression<double>? proteinG,
    Expression<double>? fatG,
    Expression<double>? carbsG,
    Expression<int>? mealType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eatenAt != null) 'eaten_at': eatenAt,
      if (name != null) 'name': name,
      if (calories != null) 'calories': calories,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (mealType != null) 'meal_type': mealType,
    });
  }

  MealEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? eatenAt,
    Value<String>? name,
    Value<double>? calories,
    Value<double>? proteinG,
    Value<double>? fatG,
    Value<double>? carbsG,
    Value<MealType?>? mealType,
  }) {
    return MealEntriesCompanion(
      id: id ?? this.id,
      eatenAt: eatenAt ?? this.eatenAt,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbsG: carbsG ?? this.carbsG,
      mealType: mealType ?? this.mealType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eatenAt.present) {
      map['eaten_at'] = Variable<DateTime>(eatenAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (calories.present) {
      map['calories'] = Variable<double>(calories.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (mealType.present) {
      map['meal_type'] = Variable<int>(
        $MealEntriesTable.$convertermealTypen.toSql(mealType.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealEntriesCompanion(')
          ..write('id: $id, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('name: $name, ')
          ..write('calories: $calories, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbsG: $carbsG, ')
          ..write('mealType: $mealType')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyFatPctMeta = const VerificationMeta(
    'bodyFatPct',
  );
  @override
  late final GeneratedColumn<double> bodyFatPct = GeneratedColumn<double>(
    'body_fat_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [day, weightKg, bodyFatPct];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('body_fat_pct')) {
      context.handle(
        _bodyFatPctMeta,
        bodyFatPct.isAcceptableOrUnknown(
          data['body_fat_pct']!,
          _bodyFatPctMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  WeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntry(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      bodyFatPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_pct'],
      ),
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntry extends DataClass implements Insertable<WeightEntry> {
  final DateTime day;
  final double weightKg;
  final double? bodyFatPct;
  const WeightEntry({
    required this.day,
    required this.weightKg,
    this.bodyFatPct,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || bodyFatPct != null) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct);
    }
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      day: Value(day),
      weightKg: Value(weightKg),
      bodyFatPct: bodyFatPct == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPct),
    );
  }

  factory WeightEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntry(
      day: serializer.fromJson<DateTime>(json['day']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      bodyFatPct: serializer.fromJson<double?>(json['bodyFatPct']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'weightKg': serializer.toJson<double>(weightKg),
      'bodyFatPct': serializer.toJson<double?>(bodyFatPct),
    };
  }

  WeightEntry copyWith({
    DateTime? day,
    double? weightKg,
    Value<double?> bodyFatPct = const Value.absent(),
  }) => WeightEntry(
    day: day ?? this.day,
    weightKg: weightKg ?? this.weightKg,
    bodyFatPct: bodyFatPct.present ? bodyFatPct.value : this.bodyFatPct,
  );
  WeightEntry copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntry(
      day: data.day.present ? data.day.value : this.day,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      bodyFatPct: data.bodyFatPct.present
          ? data.bodyFatPct.value
          : this.bodyFatPct,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntry(')
          ..write('day: $day, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPct: $bodyFatPct')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, weightKg, bodyFatPct);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightEntry &&
          other.day == this.day &&
          other.weightKg == this.weightKg &&
          other.bodyFatPct == this.bodyFatPct);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntry> {
  final Value<DateTime> day;
  final Value<double> weightKg;
  final Value<double?> bodyFatPct;
  final Value<int> rowid;
  const WeightEntriesCompanion({
    this.day = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    required DateTime day,
    required double weightKg,
    this.bodyFatPct = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       weightKg = Value(weightKg);
  static Insertable<WeightEntry> custom({
    Expression<DateTime>? day,
    Expression<double>? weightKg,
    Expression<double>? bodyFatPct,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodyFatPct != null) 'body_fat_pct': bodyFatPct,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightEntriesCompanion copyWith({
    Value<DateTime>? day,
    Value<double>? weightKg,
    Value<double?>? bodyFatPct,
    Value<int>? rowid,
  }) {
    return WeightEntriesCompanion(
      day: day ?? this.day,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (bodyFatPct.present) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('day: $day, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BodyCompositionsTable extends BodyCompositions
    with TableInfo<$BodyCompositionsTable, BodyCompositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyCompositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyFatPctMeta = const VerificationMeta(
    'bodyFatPct',
  );
  @override
  late final GeneratedColumn<double> bodyFatPct = GeneratedColumn<double>(
    'body_fat_pct',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatMassKgMeta = const VerificationMeta(
    'fatMassKg',
  );
  @override
  late final GeneratedColumn<double> fatMassKg = GeneratedColumn<double>(
    'fat_mass_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skeletalMuscleKgMeta = const VerificationMeta(
    'skeletalMuscleKg',
  );
  @override
  late final GeneratedColumn<double> skeletalMuscleKg = GeneratedColumn<double>(
    'skeletal_muscle_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _muscleMassKgMeta = const VerificationMeta(
    'muscleMassKg',
  );
  @override
  late final GeneratedColumn<double> muscleMassKg = GeneratedColumn<double>(
    'muscle_mass_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterKgMeta = const VerificationMeta(
    'waterKg',
  );
  @override
  late final GeneratedColumn<double> waterKg = GeneratedColumn<double>(
    'water_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatFreeMassKgMeta = const VerificationMeta(
    'fatFreeMassKg',
  );
  @override
  late final GeneratedColumn<double> fatFreeMassKg = GeneratedColumn<double>(
    'fat_free_mass_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subcutaneousFatPctMeta =
      const VerificationMeta('subcutaneousFatPct');
  @override
  late final GeneratedColumn<double> subcutaneousFatPct =
      GeneratedColumn<double>(
        'subcutaneous_fat_pct',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _visceralFatLevelMeta = const VerificationMeta(
    'visceralFatLevel',
  );
  @override
  late final GeneratedColumn<double> visceralFatLevel = GeneratedColumn<double>(
    'visceral_fat_level',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bmrKcalMeta = const VerificationMeta(
    'bmrKcal',
  );
  @override
  late final GeneratedColumn<double> bmrKcal = GeneratedColumn<double>(
    'bmr_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _asmiMeta = const VerificationMeta('asmi');
  @override
  late final GeneratedColumn<double> asmi = GeneratedColumn<double>(
    'asmi',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyAgeMeta = const VerificationMeta(
    'bodyAge',
  );
  @override
  late final GeneratedColumn<double> bodyAge = GeneratedColumn<double>(
    'body_age',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waistCmMeta = const VerificationMeta(
    'waistCm',
  );
  @override
  late final GeneratedColumn<double> waistCm = GeneratedColumn<double>(
    'waist_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hipCmMeta = const VerificationMeta('hipCm');
  @override
  late final GeneratedColumn<double> hipCm = GeneratedColumn<double>(
    'hip_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _armCmMeta = const VerificationMeta('armCm');
  @override
  late final GeneratedColumn<double> armCm = GeneratedColumn<double>(
    'arm_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thighCmMeta = const VerificationMeta(
    'thighCm',
  );
  @override
  late final GeneratedColumn<double> thighCm = GeneratedColumn<double>(
    'thigh_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _neckCmMeta = const VerificationMeta('neckCm');
  @override
  late final GeneratedColumn<double> neckCm = GeneratedColumn<double>(
    'neck_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chestCmMeta = const VerificationMeta(
    'chestCm',
  );
  @override
  late final GeneratedColumn<double> chestCm = GeneratedColumn<double>(
    'chest_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 40),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    weightKg,
    bodyFatPct,
    fatMassKg,
    skeletalMuscleKg,
    muscleMassKg,
    waterKg,
    fatFreeMassKg,
    subcutaneousFatPct,
    visceralFatLevel,
    bmrKcal,
    asmi,
    bodyAge,
    waistCm,
    hipCm,
    armCm,
    thighCm,
    neckCm,
    chestCm,
    source,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_compositions';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyCompositionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    } else if (isInserting) {
      context.missing(_weightKgMeta);
    }
    if (data.containsKey('body_fat_pct')) {
      context.handle(
        _bodyFatPctMeta,
        bodyFatPct.isAcceptableOrUnknown(
          data['body_fat_pct']!,
          _bodyFatPctMeta,
        ),
      );
    }
    if (data.containsKey('fat_mass_kg')) {
      context.handle(
        _fatMassKgMeta,
        fatMassKg.isAcceptableOrUnknown(data['fat_mass_kg']!, _fatMassKgMeta),
      );
    }
    if (data.containsKey('skeletal_muscle_kg')) {
      context.handle(
        _skeletalMuscleKgMeta,
        skeletalMuscleKg.isAcceptableOrUnknown(
          data['skeletal_muscle_kg']!,
          _skeletalMuscleKgMeta,
        ),
      );
    }
    if (data.containsKey('muscle_mass_kg')) {
      context.handle(
        _muscleMassKgMeta,
        muscleMassKg.isAcceptableOrUnknown(
          data['muscle_mass_kg']!,
          _muscleMassKgMeta,
        ),
      );
    }
    if (data.containsKey('water_kg')) {
      context.handle(
        _waterKgMeta,
        waterKg.isAcceptableOrUnknown(data['water_kg']!, _waterKgMeta),
      );
    }
    if (data.containsKey('fat_free_mass_kg')) {
      context.handle(
        _fatFreeMassKgMeta,
        fatFreeMassKg.isAcceptableOrUnknown(
          data['fat_free_mass_kg']!,
          _fatFreeMassKgMeta,
        ),
      );
    }
    if (data.containsKey('subcutaneous_fat_pct')) {
      context.handle(
        _subcutaneousFatPctMeta,
        subcutaneousFatPct.isAcceptableOrUnknown(
          data['subcutaneous_fat_pct']!,
          _subcutaneousFatPctMeta,
        ),
      );
    }
    if (data.containsKey('visceral_fat_level')) {
      context.handle(
        _visceralFatLevelMeta,
        visceralFatLevel.isAcceptableOrUnknown(
          data['visceral_fat_level']!,
          _visceralFatLevelMeta,
        ),
      );
    }
    if (data.containsKey('bmr_kcal')) {
      context.handle(
        _bmrKcalMeta,
        bmrKcal.isAcceptableOrUnknown(data['bmr_kcal']!, _bmrKcalMeta),
      );
    }
    if (data.containsKey('asmi')) {
      context.handle(
        _asmiMeta,
        asmi.isAcceptableOrUnknown(data['asmi']!, _asmiMeta),
      );
    }
    if (data.containsKey('body_age')) {
      context.handle(
        _bodyAgeMeta,
        bodyAge.isAcceptableOrUnknown(data['body_age']!, _bodyAgeMeta),
      );
    }
    if (data.containsKey('waist_cm')) {
      context.handle(
        _waistCmMeta,
        waistCm.isAcceptableOrUnknown(data['waist_cm']!, _waistCmMeta),
      );
    }
    if (data.containsKey('hip_cm')) {
      context.handle(
        _hipCmMeta,
        hipCm.isAcceptableOrUnknown(data['hip_cm']!, _hipCmMeta),
      );
    }
    if (data.containsKey('arm_cm')) {
      context.handle(
        _armCmMeta,
        armCm.isAcceptableOrUnknown(data['arm_cm']!, _armCmMeta),
      );
    }
    if (data.containsKey('thigh_cm')) {
      context.handle(
        _thighCmMeta,
        thighCm.isAcceptableOrUnknown(data['thigh_cm']!, _thighCmMeta),
      );
    }
    if (data.containsKey('neck_cm')) {
      context.handle(
        _neckCmMeta,
        neckCm.isAcceptableOrUnknown(data['neck_cm']!, _neckCmMeta),
      );
    }
    if (data.containsKey('chest_cm')) {
      context.handle(
        _chestCmMeta,
        chestCm.isAcceptableOrUnknown(data['chest_cm']!, _chestCmMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  BodyCompositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyCompositionRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      )!,
      bodyFatPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_fat_pct'],
      ),
      fatMassKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_mass_kg'],
      ),
      skeletalMuscleKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}skeletal_muscle_kg'],
      ),
      muscleMassKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}muscle_mass_kg'],
      ),
      waterKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_kg'],
      ),
      fatFreeMassKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_free_mass_kg'],
      ),
      subcutaneousFatPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}subcutaneous_fat_pct'],
      ),
      visceralFatLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}visceral_fat_level'],
      ),
      bmrKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bmr_kcal'],
      ),
      asmi: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}asmi'],
      ),
      bodyAge: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}body_age'],
      ),
      waistCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}waist_cm'],
      ),
      hipCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hip_cm'],
      ),
      armCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}arm_cm'],
      ),
      thighCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}thigh_cm'],
      ),
      neckCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}neck_cm'],
      ),
      chestCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chest_cm'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $BodyCompositionsTable createAlias(String alias) {
    return $BodyCompositionsTable(attachedDatabase, alias);
  }
}

class BodyCompositionRow extends DataClass
    implements Insertable<BodyCompositionRow> {
  final DateTime day;
  final double weightKg;
  final double? bodyFatPct;
  final double? fatMassKg;
  final double? skeletalMuscleKg;
  final double? muscleMassKg;
  final double? waterKg;
  final double? fatFreeMassKg;
  final double? subcutaneousFatPct;
  final double? visceralFatLevel;
  final double? bmrKcal;
  final double? asmi;
  final double? bodyAge;
  final double? waistCm;
  final double? hipCm;
  final double? armCm;
  final double? thighCm;
  final double? neckCm;
  final double? chestCm;

  /// 量測工具，例如「InBody」或體脂計的 App 名稱。
  final String? source;

  /// 量測條件備註，例如「早上空腹」「生理期第 2 天」。
  final String? note;
  const BodyCompositionRow({
    required this.day,
    required this.weightKg,
    this.bodyFatPct,
    this.fatMassKg,
    this.skeletalMuscleKg,
    this.muscleMassKg,
    this.waterKg,
    this.fatFreeMassKg,
    this.subcutaneousFatPct,
    this.visceralFatLevel,
    this.bmrKcal,
    this.asmi,
    this.bodyAge,
    this.waistCm,
    this.hipCm,
    this.armCm,
    this.thighCm,
    this.neckCm,
    this.chestCm,
    this.source,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['weight_kg'] = Variable<double>(weightKg);
    if (!nullToAbsent || bodyFatPct != null) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct);
    }
    if (!nullToAbsent || fatMassKg != null) {
      map['fat_mass_kg'] = Variable<double>(fatMassKg);
    }
    if (!nullToAbsent || skeletalMuscleKg != null) {
      map['skeletal_muscle_kg'] = Variable<double>(skeletalMuscleKg);
    }
    if (!nullToAbsent || muscleMassKg != null) {
      map['muscle_mass_kg'] = Variable<double>(muscleMassKg);
    }
    if (!nullToAbsent || waterKg != null) {
      map['water_kg'] = Variable<double>(waterKg);
    }
    if (!nullToAbsent || fatFreeMassKg != null) {
      map['fat_free_mass_kg'] = Variable<double>(fatFreeMassKg);
    }
    if (!nullToAbsent || subcutaneousFatPct != null) {
      map['subcutaneous_fat_pct'] = Variable<double>(subcutaneousFatPct);
    }
    if (!nullToAbsent || visceralFatLevel != null) {
      map['visceral_fat_level'] = Variable<double>(visceralFatLevel);
    }
    if (!nullToAbsent || bmrKcal != null) {
      map['bmr_kcal'] = Variable<double>(bmrKcal);
    }
    if (!nullToAbsent || asmi != null) {
      map['asmi'] = Variable<double>(asmi);
    }
    if (!nullToAbsent || bodyAge != null) {
      map['body_age'] = Variable<double>(bodyAge);
    }
    if (!nullToAbsent || waistCm != null) {
      map['waist_cm'] = Variable<double>(waistCm);
    }
    if (!nullToAbsent || hipCm != null) {
      map['hip_cm'] = Variable<double>(hipCm);
    }
    if (!nullToAbsent || armCm != null) {
      map['arm_cm'] = Variable<double>(armCm);
    }
    if (!nullToAbsent || thighCm != null) {
      map['thigh_cm'] = Variable<double>(thighCm);
    }
    if (!nullToAbsent || neckCm != null) {
      map['neck_cm'] = Variable<double>(neckCm);
    }
    if (!nullToAbsent || chestCm != null) {
      map['chest_cm'] = Variable<double>(chestCm);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  BodyCompositionsCompanion toCompanion(bool nullToAbsent) {
    return BodyCompositionsCompanion(
      day: Value(day),
      weightKg: Value(weightKg),
      bodyFatPct: bodyFatPct == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFatPct),
      fatMassKg: fatMassKg == null && nullToAbsent
          ? const Value.absent()
          : Value(fatMassKg),
      skeletalMuscleKg: skeletalMuscleKg == null && nullToAbsent
          ? const Value.absent()
          : Value(skeletalMuscleKg),
      muscleMassKg: muscleMassKg == null && nullToAbsent
          ? const Value.absent()
          : Value(muscleMassKg),
      waterKg: waterKg == null && nullToAbsent
          ? const Value.absent()
          : Value(waterKg),
      fatFreeMassKg: fatFreeMassKg == null && nullToAbsent
          ? const Value.absent()
          : Value(fatFreeMassKg),
      subcutaneousFatPct: subcutaneousFatPct == null && nullToAbsent
          ? const Value.absent()
          : Value(subcutaneousFatPct),
      visceralFatLevel: visceralFatLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(visceralFatLevel),
      bmrKcal: bmrKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(bmrKcal),
      asmi: asmi == null && nullToAbsent ? const Value.absent() : Value(asmi),
      bodyAge: bodyAge == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyAge),
      waistCm: waistCm == null && nullToAbsent
          ? const Value.absent()
          : Value(waistCm),
      hipCm: hipCm == null && nullToAbsent
          ? const Value.absent()
          : Value(hipCm),
      armCm: armCm == null && nullToAbsent
          ? const Value.absent()
          : Value(armCm),
      thighCm: thighCm == null && nullToAbsent
          ? const Value.absent()
          : Value(thighCm),
      neckCm: neckCm == null && nullToAbsent
          ? const Value.absent()
          : Value(neckCm),
      chestCm: chestCm == null && nullToAbsent
          ? const Value.absent()
          : Value(chestCm),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory BodyCompositionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyCompositionRow(
      day: serializer.fromJson<DateTime>(json['day']),
      weightKg: serializer.fromJson<double>(json['weightKg']),
      bodyFatPct: serializer.fromJson<double?>(json['bodyFatPct']),
      fatMassKg: serializer.fromJson<double?>(json['fatMassKg']),
      skeletalMuscleKg: serializer.fromJson<double?>(json['skeletalMuscleKg']),
      muscleMassKg: serializer.fromJson<double?>(json['muscleMassKg']),
      waterKg: serializer.fromJson<double?>(json['waterKg']),
      fatFreeMassKg: serializer.fromJson<double?>(json['fatFreeMassKg']),
      subcutaneousFatPct: serializer.fromJson<double?>(
        json['subcutaneousFatPct'],
      ),
      visceralFatLevel: serializer.fromJson<double?>(json['visceralFatLevel']),
      bmrKcal: serializer.fromJson<double?>(json['bmrKcal']),
      asmi: serializer.fromJson<double?>(json['asmi']),
      bodyAge: serializer.fromJson<double?>(json['bodyAge']),
      waistCm: serializer.fromJson<double?>(json['waistCm']),
      hipCm: serializer.fromJson<double?>(json['hipCm']),
      armCm: serializer.fromJson<double?>(json['armCm']),
      thighCm: serializer.fromJson<double?>(json['thighCm']),
      neckCm: serializer.fromJson<double?>(json['neckCm']),
      chestCm: serializer.fromJson<double?>(json['chestCm']),
      source: serializer.fromJson<String?>(json['source']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'weightKg': serializer.toJson<double>(weightKg),
      'bodyFatPct': serializer.toJson<double?>(bodyFatPct),
      'fatMassKg': serializer.toJson<double?>(fatMassKg),
      'skeletalMuscleKg': serializer.toJson<double?>(skeletalMuscleKg),
      'muscleMassKg': serializer.toJson<double?>(muscleMassKg),
      'waterKg': serializer.toJson<double?>(waterKg),
      'fatFreeMassKg': serializer.toJson<double?>(fatFreeMassKg),
      'subcutaneousFatPct': serializer.toJson<double?>(subcutaneousFatPct),
      'visceralFatLevel': serializer.toJson<double?>(visceralFatLevel),
      'bmrKcal': serializer.toJson<double?>(bmrKcal),
      'asmi': serializer.toJson<double?>(asmi),
      'bodyAge': serializer.toJson<double?>(bodyAge),
      'waistCm': serializer.toJson<double?>(waistCm),
      'hipCm': serializer.toJson<double?>(hipCm),
      'armCm': serializer.toJson<double?>(armCm),
      'thighCm': serializer.toJson<double?>(thighCm),
      'neckCm': serializer.toJson<double?>(neckCm),
      'chestCm': serializer.toJson<double?>(chestCm),
      'source': serializer.toJson<String?>(source),
      'note': serializer.toJson<String?>(note),
    };
  }

  BodyCompositionRow copyWith({
    DateTime? day,
    double? weightKg,
    Value<double?> bodyFatPct = const Value.absent(),
    Value<double?> fatMassKg = const Value.absent(),
    Value<double?> skeletalMuscleKg = const Value.absent(),
    Value<double?> muscleMassKg = const Value.absent(),
    Value<double?> waterKg = const Value.absent(),
    Value<double?> fatFreeMassKg = const Value.absent(),
    Value<double?> subcutaneousFatPct = const Value.absent(),
    Value<double?> visceralFatLevel = const Value.absent(),
    Value<double?> bmrKcal = const Value.absent(),
    Value<double?> asmi = const Value.absent(),
    Value<double?> bodyAge = const Value.absent(),
    Value<double?> waistCm = const Value.absent(),
    Value<double?> hipCm = const Value.absent(),
    Value<double?> armCm = const Value.absent(),
    Value<double?> thighCm = const Value.absent(),
    Value<double?> neckCm = const Value.absent(),
    Value<double?> chestCm = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => BodyCompositionRow(
    day: day ?? this.day,
    weightKg: weightKg ?? this.weightKg,
    bodyFatPct: bodyFatPct.present ? bodyFatPct.value : this.bodyFatPct,
    fatMassKg: fatMassKg.present ? fatMassKg.value : this.fatMassKg,
    skeletalMuscleKg: skeletalMuscleKg.present
        ? skeletalMuscleKg.value
        : this.skeletalMuscleKg,
    muscleMassKg: muscleMassKg.present ? muscleMassKg.value : this.muscleMassKg,
    waterKg: waterKg.present ? waterKg.value : this.waterKg,
    fatFreeMassKg: fatFreeMassKg.present
        ? fatFreeMassKg.value
        : this.fatFreeMassKg,
    subcutaneousFatPct: subcutaneousFatPct.present
        ? subcutaneousFatPct.value
        : this.subcutaneousFatPct,
    visceralFatLevel: visceralFatLevel.present
        ? visceralFatLevel.value
        : this.visceralFatLevel,
    bmrKcal: bmrKcal.present ? bmrKcal.value : this.bmrKcal,
    asmi: asmi.present ? asmi.value : this.asmi,
    bodyAge: bodyAge.present ? bodyAge.value : this.bodyAge,
    waistCm: waistCm.present ? waistCm.value : this.waistCm,
    hipCm: hipCm.present ? hipCm.value : this.hipCm,
    armCm: armCm.present ? armCm.value : this.armCm,
    thighCm: thighCm.present ? thighCm.value : this.thighCm,
    neckCm: neckCm.present ? neckCm.value : this.neckCm,
    chestCm: chestCm.present ? chestCm.value : this.chestCm,
    source: source.present ? source.value : this.source,
    note: note.present ? note.value : this.note,
  );
  BodyCompositionRow copyWithCompanion(BodyCompositionsCompanion data) {
    return BodyCompositionRow(
      day: data.day.present ? data.day.value : this.day,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      bodyFatPct: data.bodyFatPct.present
          ? data.bodyFatPct.value
          : this.bodyFatPct,
      fatMassKg: data.fatMassKg.present ? data.fatMassKg.value : this.fatMassKg,
      skeletalMuscleKg: data.skeletalMuscleKg.present
          ? data.skeletalMuscleKg.value
          : this.skeletalMuscleKg,
      muscleMassKg: data.muscleMassKg.present
          ? data.muscleMassKg.value
          : this.muscleMassKg,
      waterKg: data.waterKg.present ? data.waterKg.value : this.waterKg,
      fatFreeMassKg: data.fatFreeMassKg.present
          ? data.fatFreeMassKg.value
          : this.fatFreeMassKg,
      subcutaneousFatPct: data.subcutaneousFatPct.present
          ? data.subcutaneousFatPct.value
          : this.subcutaneousFatPct,
      visceralFatLevel: data.visceralFatLevel.present
          ? data.visceralFatLevel.value
          : this.visceralFatLevel,
      bmrKcal: data.bmrKcal.present ? data.bmrKcal.value : this.bmrKcal,
      asmi: data.asmi.present ? data.asmi.value : this.asmi,
      bodyAge: data.bodyAge.present ? data.bodyAge.value : this.bodyAge,
      waistCm: data.waistCm.present ? data.waistCm.value : this.waistCm,
      hipCm: data.hipCm.present ? data.hipCm.value : this.hipCm,
      armCm: data.armCm.present ? data.armCm.value : this.armCm,
      thighCm: data.thighCm.present ? data.thighCm.value : this.thighCm,
      neckCm: data.neckCm.present ? data.neckCm.value : this.neckCm,
      chestCm: data.chestCm.present ? data.chestCm.value : this.chestCm,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyCompositionRow(')
          ..write('day: $day, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('fatMassKg: $fatMassKg, ')
          ..write('skeletalMuscleKg: $skeletalMuscleKg, ')
          ..write('muscleMassKg: $muscleMassKg, ')
          ..write('waterKg: $waterKg, ')
          ..write('fatFreeMassKg: $fatFreeMassKg, ')
          ..write('subcutaneousFatPct: $subcutaneousFatPct, ')
          ..write('visceralFatLevel: $visceralFatLevel, ')
          ..write('bmrKcal: $bmrKcal, ')
          ..write('asmi: $asmi, ')
          ..write('bodyAge: $bodyAge, ')
          ..write('waistCm: $waistCm, ')
          ..write('hipCm: $hipCm, ')
          ..write('armCm: $armCm, ')
          ..write('thighCm: $thighCm, ')
          ..write('neckCm: $neckCm, ')
          ..write('chestCm: $chestCm, ')
          ..write('source: $source, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    day,
    weightKg,
    bodyFatPct,
    fatMassKg,
    skeletalMuscleKg,
    muscleMassKg,
    waterKg,
    fatFreeMassKg,
    subcutaneousFatPct,
    visceralFatLevel,
    bmrKcal,
    asmi,
    bodyAge,
    waistCm,
    hipCm,
    armCm,
    thighCm,
    neckCm,
    chestCm,
    source,
    note,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyCompositionRow &&
          other.day == this.day &&
          other.weightKg == this.weightKg &&
          other.bodyFatPct == this.bodyFatPct &&
          other.fatMassKg == this.fatMassKg &&
          other.skeletalMuscleKg == this.skeletalMuscleKg &&
          other.muscleMassKg == this.muscleMassKg &&
          other.waterKg == this.waterKg &&
          other.fatFreeMassKg == this.fatFreeMassKg &&
          other.subcutaneousFatPct == this.subcutaneousFatPct &&
          other.visceralFatLevel == this.visceralFatLevel &&
          other.bmrKcal == this.bmrKcal &&
          other.asmi == this.asmi &&
          other.bodyAge == this.bodyAge &&
          other.waistCm == this.waistCm &&
          other.hipCm == this.hipCm &&
          other.armCm == this.armCm &&
          other.thighCm == this.thighCm &&
          other.neckCm == this.neckCm &&
          other.chestCm == this.chestCm &&
          other.source == this.source &&
          other.note == this.note);
}

class BodyCompositionsCompanion extends UpdateCompanion<BodyCompositionRow> {
  final Value<DateTime> day;
  final Value<double> weightKg;
  final Value<double?> bodyFatPct;
  final Value<double?> fatMassKg;
  final Value<double?> skeletalMuscleKg;
  final Value<double?> muscleMassKg;
  final Value<double?> waterKg;
  final Value<double?> fatFreeMassKg;
  final Value<double?> subcutaneousFatPct;
  final Value<double?> visceralFatLevel;
  final Value<double?> bmrKcal;
  final Value<double?> asmi;
  final Value<double?> bodyAge;
  final Value<double?> waistCm;
  final Value<double?> hipCm;
  final Value<double?> armCm;
  final Value<double?> thighCm;
  final Value<double?> neckCm;
  final Value<double?> chestCm;
  final Value<String?> source;
  final Value<String?> note;
  final Value<int> rowid;
  const BodyCompositionsCompanion({
    this.day = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.bodyFatPct = const Value.absent(),
    this.fatMassKg = const Value.absent(),
    this.skeletalMuscleKg = const Value.absent(),
    this.muscleMassKg = const Value.absent(),
    this.waterKg = const Value.absent(),
    this.fatFreeMassKg = const Value.absent(),
    this.subcutaneousFatPct = const Value.absent(),
    this.visceralFatLevel = const Value.absent(),
    this.bmrKcal = const Value.absent(),
    this.asmi = const Value.absent(),
    this.bodyAge = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.hipCm = const Value.absent(),
    this.armCm = const Value.absent(),
    this.thighCm = const Value.absent(),
    this.neckCm = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyCompositionsCompanion.insert({
    required DateTime day,
    required double weightKg,
    this.bodyFatPct = const Value.absent(),
    this.fatMassKg = const Value.absent(),
    this.skeletalMuscleKg = const Value.absent(),
    this.muscleMassKg = const Value.absent(),
    this.waterKg = const Value.absent(),
    this.fatFreeMassKg = const Value.absent(),
    this.subcutaneousFatPct = const Value.absent(),
    this.visceralFatLevel = const Value.absent(),
    this.bmrKcal = const Value.absent(),
    this.asmi = const Value.absent(),
    this.bodyAge = const Value.absent(),
    this.waistCm = const Value.absent(),
    this.hipCm = const Value.absent(),
    this.armCm = const Value.absent(),
    this.thighCm = const Value.absent(),
    this.neckCm = const Value.absent(),
    this.chestCm = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       weightKg = Value(weightKg);
  static Insertable<BodyCompositionRow> custom({
    Expression<DateTime>? day,
    Expression<double>? weightKg,
    Expression<double>? bodyFatPct,
    Expression<double>? fatMassKg,
    Expression<double>? skeletalMuscleKg,
    Expression<double>? muscleMassKg,
    Expression<double>? waterKg,
    Expression<double>? fatFreeMassKg,
    Expression<double>? subcutaneousFatPct,
    Expression<double>? visceralFatLevel,
    Expression<double>? bmrKcal,
    Expression<double>? asmi,
    Expression<double>? bodyAge,
    Expression<double>? waistCm,
    Expression<double>? hipCm,
    Expression<double>? armCm,
    Expression<double>? thighCm,
    Expression<double>? neckCm,
    Expression<double>? chestCm,
    Expression<String>? source,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (weightKg != null) 'weight_kg': weightKg,
      if (bodyFatPct != null) 'body_fat_pct': bodyFatPct,
      if (fatMassKg != null) 'fat_mass_kg': fatMassKg,
      if (skeletalMuscleKg != null) 'skeletal_muscle_kg': skeletalMuscleKg,
      if (muscleMassKg != null) 'muscle_mass_kg': muscleMassKg,
      if (waterKg != null) 'water_kg': waterKg,
      if (fatFreeMassKg != null) 'fat_free_mass_kg': fatFreeMassKg,
      if (subcutaneousFatPct != null)
        'subcutaneous_fat_pct': subcutaneousFatPct,
      if (visceralFatLevel != null) 'visceral_fat_level': visceralFatLevel,
      if (bmrKcal != null) 'bmr_kcal': bmrKcal,
      if (asmi != null) 'asmi': asmi,
      if (bodyAge != null) 'body_age': bodyAge,
      if (waistCm != null) 'waist_cm': waistCm,
      if (hipCm != null) 'hip_cm': hipCm,
      if (armCm != null) 'arm_cm': armCm,
      if (thighCm != null) 'thigh_cm': thighCm,
      if (neckCm != null) 'neck_cm': neckCm,
      if (chestCm != null) 'chest_cm': chestCm,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyCompositionsCompanion copyWith({
    Value<DateTime>? day,
    Value<double>? weightKg,
    Value<double?>? bodyFatPct,
    Value<double?>? fatMassKg,
    Value<double?>? skeletalMuscleKg,
    Value<double?>? muscleMassKg,
    Value<double?>? waterKg,
    Value<double?>? fatFreeMassKg,
    Value<double?>? subcutaneousFatPct,
    Value<double?>? visceralFatLevel,
    Value<double?>? bmrKcal,
    Value<double?>? asmi,
    Value<double?>? bodyAge,
    Value<double?>? waistCm,
    Value<double?>? hipCm,
    Value<double?>? armCm,
    Value<double?>? thighCm,
    Value<double?>? neckCm,
    Value<double?>? chestCm,
    Value<String?>? source,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return BodyCompositionsCompanion(
      day: day ?? this.day,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      fatMassKg: fatMassKg ?? this.fatMassKg,
      skeletalMuscleKg: skeletalMuscleKg ?? this.skeletalMuscleKg,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      waterKg: waterKg ?? this.waterKg,
      fatFreeMassKg: fatFreeMassKg ?? this.fatFreeMassKg,
      subcutaneousFatPct: subcutaneousFatPct ?? this.subcutaneousFatPct,
      visceralFatLevel: visceralFatLevel ?? this.visceralFatLevel,
      bmrKcal: bmrKcal ?? this.bmrKcal,
      asmi: asmi ?? this.asmi,
      bodyAge: bodyAge ?? this.bodyAge,
      waistCm: waistCm ?? this.waistCm,
      hipCm: hipCm ?? this.hipCm,
      armCm: armCm ?? this.armCm,
      thighCm: thighCm ?? this.thighCm,
      neckCm: neckCm ?? this.neckCm,
      chestCm: chestCm ?? this.chestCm,
      source: source ?? this.source,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (bodyFatPct.present) {
      map['body_fat_pct'] = Variable<double>(bodyFatPct.value);
    }
    if (fatMassKg.present) {
      map['fat_mass_kg'] = Variable<double>(fatMassKg.value);
    }
    if (skeletalMuscleKg.present) {
      map['skeletal_muscle_kg'] = Variable<double>(skeletalMuscleKg.value);
    }
    if (muscleMassKg.present) {
      map['muscle_mass_kg'] = Variable<double>(muscleMassKg.value);
    }
    if (waterKg.present) {
      map['water_kg'] = Variable<double>(waterKg.value);
    }
    if (fatFreeMassKg.present) {
      map['fat_free_mass_kg'] = Variable<double>(fatFreeMassKg.value);
    }
    if (subcutaneousFatPct.present) {
      map['subcutaneous_fat_pct'] = Variable<double>(subcutaneousFatPct.value);
    }
    if (visceralFatLevel.present) {
      map['visceral_fat_level'] = Variable<double>(visceralFatLevel.value);
    }
    if (bmrKcal.present) {
      map['bmr_kcal'] = Variable<double>(bmrKcal.value);
    }
    if (asmi.present) {
      map['asmi'] = Variable<double>(asmi.value);
    }
    if (bodyAge.present) {
      map['body_age'] = Variable<double>(bodyAge.value);
    }
    if (waistCm.present) {
      map['waist_cm'] = Variable<double>(waistCm.value);
    }
    if (hipCm.present) {
      map['hip_cm'] = Variable<double>(hipCm.value);
    }
    if (armCm.present) {
      map['arm_cm'] = Variable<double>(armCm.value);
    }
    if (thighCm.present) {
      map['thigh_cm'] = Variable<double>(thighCm.value);
    }
    if (neckCm.present) {
      map['neck_cm'] = Variable<double>(neckCm.value);
    }
    if (chestCm.present) {
      map['chest_cm'] = Variable<double>(chestCm.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyCompositionsCompanion(')
          ..write('day: $day, ')
          ..write('weightKg: $weightKg, ')
          ..write('bodyFatPct: $bodyFatPct, ')
          ..write('fatMassKg: $fatMassKg, ')
          ..write('skeletalMuscleKg: $skeletalMuscleKg, ')
          ..write('muscleMassKg: $muscleMassKg, ')
          ..write('waterKg: $waterKg, ')
          ..write('fatFreeMassKg: $fatFreeMassKg, ')
          ..write('subcutaneousFatPct: $subcutaneousFatPct, ')
          ..write('visceralFatLevel: $visceralFatLevel, ')
          ..write('bmrKcal: $bmrKcal, ')
          ..write('asmi: $asmi, ')
          ..write('bodyAge: $bodyAge, ')
          ..write('waistCm: $waistCm, ')
          ..write('hipCm: $hipCm, ')
          ..write('armCm: $armCm, ')
          ..write('thighCm: $thighCm, ')
          ..write('neckCm: $neckCm, ')
          ..write('chestCm: $chestCm, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $MealEntriesTable mealEntries = $MealEntriesTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  late final $BodyCompositionsTable bodyCompositions = $BodyCompositionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfiles,
    mealEntries,
    weightEntries,
    bodyCompositions,
  ];
}

typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      required Sex sex,
      required int age,
      required double heightCm,
      required double weightKg,
      required ActivityLevel activity,
      required Goal goal,
      Value<double?> bodyFatPct,
      Value<double?> targetWeightKg,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<Sex> sex,
      Value<int> age,
      Value<double> heightCm,
      Value<double> weightKg,
      Value<ActivityLevel> activity,
      Value<Goal> goal,
      Value<double?> bodyFatPct,
      Value<double?> targetWeightKg,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Sex, Sex, int> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ActivityLevel, ActivityLevel, int>
  get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Goal, Goal, int> get goal =>
      $composableBuilder(
        column: $table.goal,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Sex, int> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActivityLevel, int> get activity =>
      $composableBuilder(column: $table.activity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Goal, int> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetWeightKg => $composableBuilder(
    column: $table.targetWeightKg,
    builder: (column) => column,
  );
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfileRow,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfileRow,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
          ),
          UserProfileRow,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<Sex> sex = const Value.absent(),
                Value<int> age = const Value.absent(),
                Value<double> heightCm = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<ActivityLevel> activity = const Value.absent(),
                Value<Goal> goal = const Value.absent(),
                Value<double?> bodyFatPct = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                sex: sex,
                age: age,
                heightCm: heightCm,
                weightKg: weightKg,
                activity: activity,
                goal: goal,
                bodyFatPct: bodyFatPct,
                targetWeightKg: targetWeightKg,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required Sex sex,
                required int age,
                required double heightCm,
                required double weightKg,
                required ActivityLevel activity,
                required Goal goal,
                Value<double?> bodyFatPct = const Value.absent(),
                Value<double?> targetWeightKg = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                sex: sex,
                age: age,
                heightCm: heightCm,
                weightKg: weightKg,
                activity: activity,
                goal: goal,
                bodyFatPct: bodyFatPct,
                targetWeightKg: targetWeightKg,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfileRow,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfileRow,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfileRow>,
      ),
      UserProfileRow,
      PrefetchHooks Function()
    >;
typedef $$MealEntriesTableCreateCompanionBuilder =
    MealEntriesCompanion Function({
      Value<int> id,
      required DateTime eatenAt,
      required String name,
      required double calories,
      required double proteinG,
      required double fatG,
      required double carbsG,
      Value<MealType?> mealType,
    });
typedef $$MealEntriesTableUpdateCompanionBuilder =
    MealEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> eatenAt,
      Value<String> name,
      Value<double> calories,
      Value<double> proteinG,
      Value<double> fatG,
      Value<double> carbsG,
      Value<MealType?> mealType,
    });

class $$MealEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealType?, MealType, int> get mealType =>
      $composableBuilder(
        column: $table.mealType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$MealEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calories => $composableBuilder(
    column: $table.calories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mealType => $composableBuilder(
    column: $table.mealType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get eatenAt =>
      $composableBuilder(column: $table.eatenAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MealType?, int> get mealType =>
      $composableBuilder(column: $table.mealType, builder: (column) => column);
}

class $$MealEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealEntriesTable,
          MealEntry,
          $$MealEntriesTableFilterComposer,
          $$MealEntriesTableOrderingComposer,
          $$MealEntriesTableAnnotationComposer,
          $$MealEntriesTableCreateCompanionBuilder,
          $$MealEntriesTableUpdateCompanionBuilder,
          (
            MealEntry,
            BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntry>,
          ),
          MealEntry,
          PrefetchHooks Function()
        > {
  $$MealEntriesTableTableManager(_$AppDatabase db, $MealEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> eatenAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> calories = const Value.absent(),
                Value<double> proteinG = const Value.absent(),
                Value<double> fatG = const Value.absent(),
                Value<double> carbsG = const Value.absent(),
                Value<MealType?> mealType = const Value.absent(),
              }) => MealEntriesCompanion(
                id: id,
                eatenAt: eatenAt,
                name: name,
                calories: calories,
                proteinG: proteinG,
                fatG: fatG,
                carbsG: carbsG,
                mealType: mealType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime eatenAt,
                required String name,
                required double calories,
                required double proteinG,
                required double fatG,
                required double carbsG,
                Value<MealType?> mealType = const Value.absent(),
              }) => MealEntriesCompanion.insert(
                id: id,
                eatenAt: eatenAt,
                name: name,
                calories: calories,
                proteinG: proteinG,
                fatG: fatG,
                carbsG: carbsG,
                mealType: mealType,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealEntriesTable,
      MealEntry,
      $$MealEntriesTableFilterComposer,
      $$MealEntriesTableOrderingComposer,
      $$MealEntriesTableAnnotationComposer,
      $$MealEntriesTableCreateCompanionBuilder,
      $$MealEntriesTableUpdateCompanionBuilder,
      (MealEntry, BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntry>),
      MealEntry,
      PrefetchHooks Function()
    >;
typedef $$WeightEntriesTableCreateCompanionBuilder =
    WeightEntriesCompanion Function({
      required DateTime day,
      required double weightKg,
      Value<double?> bodyFatPct,
      Value<int> rowid,
    });
typedef $$WeightEntriesTableUpdateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<DateTime> day,
      Value<double> weightKg,
      Value<double?> bodyFatPct,
      Value<int> rowid,
    });

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => column,
  );
}

class $$WeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightEntriesTable,
          WeightEntry,
          $$WeightEntriesTableFilterComposer,
          $$WeightEntriesTableOrderingComposer,
          $$WeightEntriesTableAnnotationComposer,
          $$WeightEntriesTableCreateCompanionBuilder,
          $$WeightEntriesTableUpdateCompanionBuilder,
          (
            WeightEntry,
            BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
          ),
          WeightEntry,
          PrefetchHooks Function()
        > {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> day = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<double?> bodyFatPct = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightEntriesCompanion(
                day: day,
                weightKg: weightKg,
                bodyFatPct: bodyFatPct,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime day,
                required double weightKg,
                Value<double?> bodyFatPct = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightEntriesCompanion.insert(
                day: day,
                weightKg: weightKg,
                bodyFatPct: bodyFatPct,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightEntriesTable,
      WeightEntry,
      $$WeightEntriesTableFilterComposer,
      $$WeightEntriesTableOrderingComposer,
      $$WeightEntriesTableAnnotationComposer,
      $$WeightEntriesTableCreateCompanionBuilder,
      $$WeightEntriesTableUpdateCompanionBuilder,
      (
        WeightEntry,
        BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
      ),
      WeightEntry,
      PrefetchHooks Function()
    >;
typedef $$BodyCompositionsTableCreateCompanionBuilder =
    BodyCompositionsCompanion Function({
      required DateTime day,
      required double weightKg,
      Value<double?> bodyFatPct,
      Value<double?> fatMassKg,
      Value<double?> skeletalMuscleKg,
      Value<double?> muscleMassKg,
      Value<double?> waterKg,
      Value<double?> fatFreeMassKg,
      Value<double?> subcutaneousFatPct,
      Value<double?> visceralFatLevel,
      Value<double?> bmrKcal,
      Value<double?> asmi,
      Value<double?> bodyAge,
      Value<double?> waistCm,
      Value<double?> hipCm,
      Value<double?> armCm,
      Value<double?> thighCm,
      Value<double?> neckCm,
      Value<double?> chestCm,
      Value<String?> source,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$BodyCompositionsTableUpdateCompanionBuilder =
    BodyCompositionsCompanion Function({
      Value<DateTime> day,
      Value<double> weightKg,
      Value<double?> bodyFatPct,
      Value<double?> fatMassKg,
      Value<double?> skeletalMuscleKg,
      Value<double?> muscleMassKg,
      Value<double?> waterKg,
      Value<double?> fatFreeMassKg,
      Value<double?> subcutaneousFatPct,
      Value<double?> visceralFatLevel,
      Value<double?> bmrKcal,
      Value<double?> asmi,
      Value<double?> bodyAge,
      Value<double?> waistCm,
      Value<double?> hipCm,
      Value<double?> armCm,
      Value<double?> thighCm,
      Value<double?> neckCm,
      Value<double?> chestCm,
      Value<String?> source,
      Value<String?> note,
      Value<int> rowid,
    });

class $$BodyCompositionsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyCompositionsTable> {
  $$BodyCompositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatMassKg => $composableBuilder(
    column: $table.fatMassKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get skeletalMuscleKg => $composableBuilder(
    column: $table.skeletalMuscleKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get muscleMassKg => $composableBuilder(
    column: $table.muscleMassKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterKg => $composableBuilder(
    column: $table.waterKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatFreeMassKg => $composableBuilder(
    column: $table.fatFreeMassKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subcutaneousFatPct => $composableBuilder(
    column: $table.subcutaneousFatPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get visceralFatLevel => $composableBuilder(
    column: $table.visceralFatLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bmrKcal => $composableBuilder(
    column: $table.bmrKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get asmi => $composableBuilder(
    column: $table.asmi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bodyAge => $composableBuilder(
    column: $table.bodyAge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hipCm => $composableBuilder(
    column: $table.hipCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get armCm => $composableBuilder(
    column: $table.armCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thighCm => $composableBuilder(
    column: $table.thighCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get neckCm => $composableBuilder(
    column: $table.neckCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyCompositionsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyCompositionsTable> {
  $$BodyCompositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatMassKg => $composableBuilder(
    column: $table.fatMassKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get skeletalMuscleKg => $composableBuilder(
    column: $table.skeletalMuscleKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get muscleMassKg => $composableBuilder(
    column: $table.muscleMassKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterKg => $composableBuilder(
    column: $table.waterKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatFreeMassKg => $composableBuilder(
    column: $table.fatFreeMassKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subcutaneousFatPct => $composableBuilder(
    column: $table.subcutaneousFatPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get visceralFatLevel => $composableBuilder(
    column: $table.visceralFatLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bmrKcal => $composableBuilder(
    column: $table.bmrKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get asmi => $composableBuilder(
    column: $table.asmi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bodyAge => $composableBuilder(
    column: $table.bodyAge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waistCm => $composableBuilder(
    column: $table.waistCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hipCm => $composableBuilder(
    column: $table.hipCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get armCm => $composableBuilder(
    column: $table.armCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thighCm => $composableBuilder(
    column: $table.thighCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get neckCm => $composableBuilder(
    column: $table.neckCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chestCm => $composableBuilder(
    column: $table.chestCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyCompositionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyCompositionsTable> {
  $$BodyCompositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get bodyFatPct => $composableBuilder(
    column: $table.bodyFatPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fatMassKg =>
      $composableBuilder(column: $table.fatMassKg, builder: (column) => column);

  GeneratedColumn<double> get skeletalMuscleKg => $composableBuilder(
    column: $table.skeletalMuscleKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get muscleMassKg => $composableBuilder(
    column: $table.muscleMassKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get waterKg =>
      $composableBuilder(column: $table.waterKg, builder: (column) => column);

  GeneratedColumn<double> get fatFreeMassKg => $composableBuilder(
    column: $table.fatFreeMassKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subcutaneousFatPct => $composableBuilder(
    column: $table.subcutaneousFatPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get visceralFatLevel => $composableBuilder(
    column: $table.visceralFatLevel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bmrKcal =>
      $composableBuilder(column: $table.bmrKcal, builder: (column) => column);

  GeneratedColumn<double> get asmi =>
      $composableBuilder(column: $table.asmi, builder: (column) => column);

  GeneratedColumn<double> get bodyAge =>
      $composableBuilder(column: $table.bodyAge, builder: (column) => column);

  GeneratedColumn<double> get waistCm =>
      $composableBuilder(column: $table.waistCm, builder: (column) => column);

  GeneratedColumn<double> get hipCm =>
      $composableBuilder(column: $table.hipCm, builder: (column) => column);

  GeneratedColumn<double> get armCm =>
      $composableBuilder(column: $table.armCm, builder: (column) => column);

  GeneratedColumn<double> get thighCm =>
      $composableBuilder(column: $table.thighCm, builder: (column) => column);

  GeneratedColumn<double> get neckCm =>
      $composableBuilder(column: $table.neckCm, builder: (column) => column);

  GeneratedColumn<double> get chestCm =>
      $composableBuilder(column: $table.chestCm, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$BodyCompositionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyCompositionsTable,
          BodyCompositionRow,
          $$BodyCompositionsTableFilterComposer,
          $$BodyCompositionsTableOrderingComposer,
          $$BodyCompositionsTableAnnotationComposer,
          $$BodyCompositionsTableCreateCompanionBuilder,
          $$BodyCompositionsTableUpdateCompanionBuilder,
          (
            BodyCompositionRow,
            BaseReferences<
              _$AppDatabase,
              $BodyCompositionsTable,
              BodyCompositionRow
            >,
          ),
          BodyCompositionRow,
          PrefetchHooks Function()
        > {
  $$BodyCompositionsTableTableManager(
    _$AppDatabase db,
    $BodyCompositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyCompositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyCompositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyCompositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> day = const Value.absent(),
                Value<double> weightKg = const Value.absent(),
                Value<double?> bodyFatPct = const Value.absent(),
                Value<double?> fatMassKg = const Value.absent(),
                Value<double?> skeletalMuscleKg = const Value.absent(),
                Value<double?> muscleMassKg = const Value.absent(),
                Value<double?> waterKg = const Value.absent(),
                Value<double?> fatFreeMassKg = const Value.absent(),
                Value<double?> subcutaneousFatPct = const Value.absent(),
                Value<double?> visceralFatLevel = const Value.absent(),
                Value<double?> bmrKcal = const Value.absent(),
                Value<double?> asmi = const Value.absent(),
                Value<double?> bodyAge = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> hipCm = const Value.absent(),
                Value<double?> armCm = const Value.absent(),
                Value<double?> thighCm = const Value.absent(),
                Value<double?> neckCm = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyCompositionsCompanion(
                day: day,
                weightKg: weightKg,
                bodyFatPct: bodyFatPct,
                fatMassKg: fatMassKg,
                skeletalMuscleKg: skeletalMuscleKg,
                muscleMassKg: muscleMassKg,
                waterKg: waterKg,
                fatFreeMassKg: fatFreeMassKg,
                subcutaneousFatPct: subcutaneousFatPct,
                visceralFatLevel: visceralFatLevel,
                bmrKcal: bmrKcal,
                asmi: asmi,
                bodyAge: bodyAge,
                waistCm: waistCm,
                hipCm: hipCm,
                armCm: armCm,
                thighCm: thighCm,
                neckCm: neckCm,
                chestCm: chestCm,
                source: source,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime day,
                required double weightKg,
                Value<double?> bodyFatPct = const Value.absent(),
                Value<double?> fatMassKg = const Value.absent(),
                Value<double?> skeletalMuscleKg = const Value.absent(),
                Value<double?> muscleMassKg = const Value.absent(),
                Value<double?> waterKg = const Value.absent(),
                Value<double?> fatFreeMassKg = const Value.absent(),
                Value<double?> subcutaneousFatPct = const Value.absent(),
                Value<double?> visceralFatLevel = const Value.absent(),
                Value<double?> bmrKcal = const Value.absent(),
                Value<double?> asmi = const Value.absent(),
                Value<double?> bodyAge = const Value.absent(),
                Value<double?> waistCm = const Value.absent(),
                Value<double?> hipCm = const Value.absent(),
                Value<double?> armCm = const Value.absent(),
                Value<double?> thighCm = const Value.absent(),
                Value<double?> neckCm = const Value.absent(),
                Value<double?> chestCm = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyCompositionsCompanion.insert(
                day: day,
                weightKg: weightKg,
                bodyFatPct: bodyFatPct,
                fatMassKg: fatMassKg,
                skeletalMuscleKg: skeletalMuscleKg,
                muscleMassKg: muscleMassKg,
                waterKg: waterKg,
                fatFreeMassKg: fatFreeMassKg,
                subcutaneousFatPct: subcutaneousFatPct,
                visceralFatLevel: visceralFatLevel,
                bmrKcal: bmrKcal,
                asmi: asmi,
                bodyAge: bodyAge,
                waistCm: waistCm,
                hipCm: hipCm,
                armCm: armCm,
                thighCm: thighCm,
                neckCm: neckCm,
                chestCm: chestCm,
                source: source,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyCompositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyCompositionsTable,
      BodyCompositionRow,
      $$BodyCompositionsTableFilterComposer,
      $$BodyCompositionsTableOrderingComposer,
      $$BodyCompositionsTableAnnotationComposer,
      $$BodyCompositionsTableCreateCompanionBuilder,
      $$BodyCompositionsTableUpdateCompanionBuilder,
      (
        BodyCompositionRow,
        BaseReferences<
          _$AppDatabase,
          $BodyCompositionsTable,
          BodyCompositionRow
        >,
      ),
      BodyCompositionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$MealEntriesTableTableManager get mealEntries =>
      $$MealEntriesTableTableManager(_db, _db.mealEntries);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
  $$BodyCompositionsTableTableManager get bodyCompositions =>
      $$BodyCompositionsTableTableManager(_db, _db.bodyCompositions);
}
