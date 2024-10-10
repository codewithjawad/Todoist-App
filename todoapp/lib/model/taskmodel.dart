class taskmodel {
  String? sId;
  String? taskname;
  String? description;
  String? priority;

  taskmodel({this.sId, this.taskname, this.description, this.priority});

  taskmodel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    taskname = json['taskname'];
    description = json['description'];
    priority = json['priority'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['taskname'] = taskname;
    data['description'] = description;
    data['priority'] = priority;
    return data;
  }
}
