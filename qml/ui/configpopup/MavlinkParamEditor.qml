import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.0
import QtQuick.Controls.Material 2.12

import Qt.labs.settings 1.0

import OpenHD 1.0

import "../../ui" as Ui
import "../elements"

// Dirty. This is opened up every time the user wants to change a parameter.
// R.n it supports int and string parameters.
// int parameters can have sequential (0,1,2,..) or custom (1000Mhz,2000Mhz,3000Mhz) enums,
// which is much more verbose to the user.

Rectangle{

    property int total_width: 300

    width: total_width
    height: parent.height
    border.color: "black"
    border.width: 5

    anchors.right: parent.right;
    anchors.top: parent.top
    //Layout.alignment: Qt.AlignRight || Qt.AlignTop
    // by default, invisble. Element becomes visible when user clicks on edit for a specific param
    visible: false
    // We set a the ground pi instance as default (such that the qt editor code completion helps us a bit),
    // but this can be replaced by the proper instance for air or camera
    property var instanceMavlinkSettingsModel: _groundPiSettingsModel

    property int customHeight: 50

    property string parameterId: "PARAM_ID_UNSET"

    property int paramValueType: 0 // 0==int, 1==string

    // These are only for int params, and also parially optional (e.g not every in param is range checked usw)
    // int param begin -----------------------------
    property int paramValueInt: 0
    property string paramExtraValueInt: "0"
    // int param end   -----------------------------

    // only for string params begin
    property string paramValueString: "ValueString"
    // only for string params end

    property string shortParamDescription: "?"

    // disable some checking we do for the user, should be used only in really rare cases
    property bool enableAdvanced: false


    function holds_int_value(){
        return paramValueType==0;
    }

    function holds_string_value(){
        return paramValueType==1;
    }

    function get_param_type_readable(){
        if(holds_int_value())return "(int)"
        return "(string)"
    }

    function param_int_min_value(){
        // Advanced passes all restrictions
        if(enableAdvanced){
            return -2147483648;
        }
        if(instanceMavlinkSettingsModel.int_param_has_min_max(parameterId)){
            return instanceMavlinkSettingsModel.int_param_get_min_value(parameterId);
        }
        // r.n all int params are unsigend
        return 0;
    }
    function param_int_max_value(){
        // Advanced passes all restrictions
        if(enableAdvanced){
            return 2147483647;
        }
        if(instanceMavlinkSettingsModel.int_param_has_min_max(parameterId)){
            return instanceMavlinkSettingsModel.int_param_get_max_value(parameterId);
        }
        return 2147483647;
    }

    function setup_for_parameter(param_id,model){
        console.log("setup_for_parameter"+param_id);
        if(model.unique_id !== param_id){
            console.log("Error wrong usage, pass in the right model");
            return;
        }
        // Every time the user wants to enable the "advanced", he needs to re-do it for every param,
        // since advanced only makes sense in the rarest case(s), e.g. when QOpenHD and OpenHD are out of sync.
        checkBoxEnableAdvanced.checked=false
        enableAdvanced=false;
        // disable by default, enable only in case it is needed
        stringEnumDynamicComboBox.visible=false
        // set param id and the value type this param holds
        parameterId=param_id;
        paramValueType=model.valueType
        shortParamDescription=model.shortDescription
        var warning_string=instanceMavlinkSettingsModel.get_warning_before_safe(parameterId);
        if(warning_string!==""){
            console.log("Show extra dialog before actually saving:"+warning_string);
            _messageBoxInstance.set_text_and_show(warning_string);
        }
        if(paramValueType==0){
            // This is an int param
            paramValueInt=model.value
            paramExtraValueInt= model.extraValue
            paramValueString="Do not use me !!!"
        }else{
            // This is a string param
            paramValueString=model.value
            paramValueInt=-1
            paramExtraValueInt= "Do not use me !!!!"
        }
        setup_spin_box_int_param()
        setup_text_input_string_param()
        parameterEditor.visible=true
    }

    // For int params we use the spin box
    function setup_spin_box_int_param(){
        if(holds_int_value()){
            // If we can treat this int value as an enum, this is the most verbose for the user
             if(instanceMavlinkSettingsModel.int_param_has_enum_keys_values(parameterId)){
                 console.log(parameterId+" has int enum mapping")
                 spinBoxInputParamtypeInt.visible=false
                 intEnumDynamicComboBox.visible=true
                 // Populate the model with the key,value pairs for this enum
                 const keys=instanceMavlinkSettingsModel.int_param_get_enum_keys(parameterId)
                 const values=instanceMavlinkSettingsModel.int_param_get_enum_values(parameterId);
                 intEnumDynamicListModel.clear()
                 var currently_selected_index=-1;
                 for (var i = 0; i < keys.length; i++) {
                     var key=keys[i];
                     var value=values[i];
                     //console.log(key,value);
                     intEnumDynamicListModel.append({title: key, value: value})
                     if(value===paramValueInt){
                         currently_selected_index=i;
                     }
                 }
                 if(currently_selected_index==-1){
                     // We are missing a description for this int value, add row
                     var new_key="Unknown("+paramValueInt+")"
                     console.log("Adding missing dummy description :"+new_key+" "+paramValueInt)
                     intEnumDynamicListModel.append({title: new_key, value: paramValueInt})
                     currently_selected_index=intEnumDynamicListModel.count-1
                 }
                 intEnumDynamicComboBox.currentIndex=currently_selected_index
                 console.log("Curr index:",currently_selected_index);
             }else{
                 // Less verbose
                 console.log("Int parameter has no int enum mapping")
                 intEnumDynamicComboBox.visible=false
                 spinBoxInputParamtypeInt.visible=true
                 spinBoxInputParamtypeInt.from=param_int_min_value()
                 spinBoxInputParamtypeInt.to=param_int_max_value()
                 spinBoxInputParamtypeInt.value=paramValueInt
             }
        }else{
            spinBoxInputParamtypeInt.visible=false
            intEnumDynamicComboBox.visible=false;
        }
    }

    // for string params we use the text input
    function setup_text_input_string_param(){
        if(holds_string_value()){
            if(instanceMavlinkSettingsModel.string_param_has_enum(parameterId)){
                console.log(parameterId+" has string enum mapping")
                // Populate the model with the key,value pairs for this enum
                const keys=instanceMavlinkSettingsModel.string_param_get_enum_keys(parameterId)
                const values=instanceMavlinkSettingsModel.string_param_get_enum_values(parameterId);
                stringEnumDynamicListModel.clear();
                var currently_selected_index=-1;
                for (var i = 0; i < keys.length; i++) {
                    var key=keys[i];
                    var value=values[i];
                    console.log(key,value);
                    stringEnumDynamicListModel.append({title: key, value: value})
                    if(value===paramValueString){
                        currently_selected_index=i;
                    }
                }
                console.log("currently_selected_index:"+currently_selected_index);
                if(currently_selected_index==-1){
                    var new_key="{"+paramValueString+"}"
                    console.log("Adding missing dummy description :"+new_key+" "+paramValueString)
                    stringEnumDynamicListModel.append({title: new_key, value: paramValueString})
                    currently_selected_index=stringEnumDynamicListModel.count-1
                }
                stringEnumDynamicComboBox.currentIndex=currently_selected_index
                console.log("Curr index:",currently_selected_index);
                stringEnumDynamicComboBox.visible=true;
            }
            textInputParamtypeString.visible=true
            textInputParamtypeString.text= paramValueString
        }else{
            textInputParamtypeString.visible=false
            stringEnumDynamicComboBox.visible=false
        }
    }


    ColumnLayout{
        width: parent.width
        height:parent.height

        spacing: 10

        Label{
            height: customHeight
            text: "Parameter editor"
            font.bold: true
            horizontalAlignment: Qt.AlignCenter
            Layout.alignment: Qt.AlignCenter
        }

        Label{
            height:customHeight
            text: qsTr(parameterId+" "+get_param_type_readable())
            horizontalAlignment: Qt.AlignCenter
            // dafuq https://stackoverflow.com/questions/35799944/text-type-alignment
            Layout.alignment: Qt.AlignCenter
        }
        Text {
            width: total_width
            height:customHeight
            id: textDescription
            text: qsTr("Description: "+shortParamDescription)
            //horizontalAlignment: Qt.AlignCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignCenter
        }

// Value edit part begin

        // Type int only begin --------------------------
        // For int values that do not have an enum mapping, we use a SpinBox such that the user can either
        // use the +/- to edit the value (for touch screen users) but also allows the user to
        // type in an int value directly with the keyboard.
        SpinBox {
            id: spinBoxInputParamtypeInt
            height: customHeight
            font.pixelSize: 14
            Layout.alignment: Qt.AlignCenter
            from: param_int_min_value()
            to: param_int_max_value()
            stepSize: 1
            value: paramValueInt
            visible: holds_int_value()

            editable: true
            onValueChanged: {

            }
        }
        // And for int values that do have an enum mapping we use a more verbose combo box and a dynamically updated model
        // The best example is the typical yes/no, or uart1,uart2,uart3,...
        ListModel{
             id: intEnumDynamicListModel
             ListElement {title: "I SHOULD NEVER APPEAR"; value: 0}
        }
        ComboBox {
            id: intEnumDynamicComboBox
            height: customHeight
            font.pixelSize: 14
            Layout.alignment: Qt.AlignCenter
            model: intEnumDynamicListModel
            textRole: "title"
            Layout.minimumWidth : total_width*0.8
            onCurrentIndexChanged: {
            }
            visible:false
        }
        // Type int only end --------------------------

        // Type string only begin --------------------------
        // if we have a mapping / pre-selected recommended choices
        ListModel{
             id: stringEnumDynamicListModel
             ListElement {title: "I SHOULD NEVER APPEAR"; value:"ERROR"}
        }

        ComboBox {
            id: stringEnumDynamicComboBox
            height: customHeight
            font.pixelSize: 14
            Layout.alignment: Qt.AlignCenter
            model: stringEnumDynamicListModel
            textRole: "title"
            Layout.minimumWidth : total_width*0.8
            onCurrentIndexChanged: {
                console.debug("currentIndex:"+currentIndex)
                if(currentIndex>=0){
                    // no idea why this is needed
                    const new_param_value=stringEnumDynamicListModel.get(currentIndex).value
                    console.debug("new_param_value:"+new_param_value)
                    textInputParamtypeString.text=new_param_value
                }
            }
            visible:false
        }

        // for strings, we always show the text input
        TextInput{
            id: textInputParamtypeString
            horizontalAlignment: Qt.AlignCenter
            height: customHeight
            text: paramValueString
            cursorVisible: false
            visible: false
            Layout.alignment: Qt.AlignCenter
        }
        // Type string only end --------------------------
        //Value edit part end

        RowLayout{
            width:parent.width
            height: 50
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            Button{
                text: "Cancel"
                Layout.alignment: Qt.AlignLeft
                onClicked: {
                    parameterEditor.visible=false
                }
            }
            Button{
                text: "Save"
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    var res=false;
                    if(paramValueType==0){
                        var value_int;
                        if(intEnumDynamicComboBox.visible){
                            value_int=intEnumDynamicListModel.get(intEnumDynamicComboBox.currentIndex).value
                        }else{
                            value_int=spinBoxInputParamtypeInt.value
                        }
                        //var value_int_as_string=spinBoxInputParamtypeInt.text
                        //var value_int = parseInt(value_int_as_string)
                        //console.log("UI set int:{"+value_int_as_string+"}={"+value_int+"}")
                        console.log("UI set int:{"+value_int+"}")
                        res=instanceMavlinkSettingsModel.try_update_parameter_int(parameterId,value_int)
                    }else{
                        var value_string=textInputParamtypeString.text
                        console.log("UI set string:{"+value_string+"}")
                        res=instanceMavlinkSettingsModel.try_update_parameter_string(parameterId,value_string);
                    }
                    if(!res){
                        console.log("Update failed")
                        _messageBoxInstance.set_text_and_show("Update failed")
                    }else{
                        if(instanceMavlinkSettingsModel.get_param_requires_manual_reboot(parameterId)){
                            _messageBoxInstance.set_text_and_show("Please reboot to apply")
                        }
                        parameterEditor.visible=false
                    }
                }
            }
        }
        CheckBox{
            width: total_width
            height:customHeight
            id: checkBoxEnableAdvanced
            //horizontalAlignment: Qt.AlignCenter
            text: qsTr("Advanced")
            Layout.alignment: Qt.AlignHCenter
            onCheckStateChanged: {
                enableAdvanced=checkBoxEnableAdvanced.checked
                // We need to refresh the input field, since aparently qt rejects values out of range
                if(holds_int_value() && enableAdvanced){
                    setup_spin_box_int_param()
                }
            }
        }
    }
}
