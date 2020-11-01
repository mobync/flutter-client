enum SyncDiffType { create, update, delete }

const Map<SyncDiffType, String> SyncDiffTypesMap = {
  SyncDiffType.create: 'create',
  SyncDiffType.update: 'update',
  SyncDiffType.delete: 'delete',
};

const Map<String, SyncDiffType> SyncDiffTypesReversedMap = {
  'create': SyncDiffType.create,
  'update': SyncDiffType.update,
  'delete': SyncDiffType.delete,
};
