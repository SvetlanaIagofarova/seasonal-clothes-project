class CloudStorageException implements Exception {
  const CloudStorageException();
}

//C in CRUD
class CouldNotCreateGarmentException extends CloudStorageException {}

//R in CRUD
class CouldNotGetAllGarmentsException extends CloudStorageException {}

//U in CRUD
class CouldNotUpdateGarmentException extends CloudStorageException {}

//D in CRUD
class CouldNotDeleteGarmentException extends CloudStorageException {}