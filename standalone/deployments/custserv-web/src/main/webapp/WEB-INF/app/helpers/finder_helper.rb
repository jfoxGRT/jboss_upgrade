module FinderHelper
    def eligible_for_reopen?(task_type_code)
    return (task_type_code == TaskType.UNASSIGNED_ENTITLEMENT_CODE)
  end
end
