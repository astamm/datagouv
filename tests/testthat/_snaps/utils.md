# find_dataset() errors when no title matches exactly

    Code
      find_dataset("Does not exist")
    Condition
      Error:
      ! No dataset titled 'Does not exist' was found on data.gouv.fr. Check the name with list_datasets().

# pick_resource() errors when the dataset has no resources

    Code
      pick_resource(dataset)
    Condition
      Error:
      ! Dataset 'Example dataset' has no resources.

# pick_resource() errors when no resource is supported

    Code
      pick_resource(dataset)
    Condition
      Error:
      ! Dataset 'Example dataset' has no resource in a supported format (CSV, TSV, TXT, XLSX or JSON).

# read_resource() errors on unsupported formats

    Code
      read_resource(mock_resource("pdf"))
    Condition
      Error:
      ! Unsupported format: pdf

