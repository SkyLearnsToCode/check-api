class CreateDateTimeTask < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    taskref = DynamicAnnotation::FieldType.where(field_type: 'task_reference').last ||
              create_field_type(field_type: 'task_reference', label: 'Task Reference')
    datetime = create_field_type field_type: 'datetime', label: 'Date / Time'
    
    at = create_annotation_type annotation_type: 'task_response_datetime', label: 'Task Response Date Time'
    create_field_instance annotation_type_object: at, name: 'response_datetime', label: 'Response', field_type_object: datetime, optional: false 
    create_field_instance annotation_type_object: at, name: 'task_datetime', label: 'Task', field_type_object: taskref, optional: false
  end
end
