import 'package:flutter_test/flutter_test.dart';
import 'package:headunit_example/rhmi.dart';

const input = """
<pluginApps><pluginApp>
    <actions>
        <unknown />
        <raAction id="2"/>
        <combinedAction id="3" sync="true" actionType="spellWord">
            <actions>
                <raAction id="4"/>
                <hmiAction id="5" targetModel="6"/>
            </actions>
        </combinedAction>
        <linkAction id="7" actionType="call" linkModel="12"/>
        <raAction id="64"/>
        <raAction id="65"/>
    </actions>
    <models>
        <unknown />
        <imageIdModel id="4" imageId="15"/>
        <textIdModel id="5" textId="70"/>
        <raBoolModel id="50"/>
        <raDataModel id="6"/>
        <raImageModel id="62"/>
        <raIntModel id="60" value="0"/>
        <raListModel id="7" modelType="EntICPlaylist"/>
        <raListModel id="74" modelType="EntICDetails"/>
        <raDataModel id="35"/>
        <raBoolModel id="36"/>
        <textIdModel id="37"/>
        <raDataModel id="38"/>
        <raDataModel id="39"/>
        <raDataModel id="40"/>
        <raDataModel id="41"/>
        <raGaugeModel id="8" modelType="Progress" min="0" max="100" value="0" increment="1"/>
        <formatDataModel id="10" formatString="%0%1">
            <models>
                <textIdModel id="11"/>
                <raDataModel id="12"/>
            </models>
        </formatDataModel>
    </models>
    <hmiStates>
        <hmiState id="46" textModel="5">
            <properties><property id="4" value="false" /></properties>
            <optionComponents>
                <separator id="121" />
                <label id="75" model="60" />
                <button id="76" action="5" model="61" />
            </optionComponents>
        </hmiState>
        <toolbarHmiState id="40" textModel="6">
            <toolbarComponents>
                <button id="41" action="3" selectAction="4" tooltipModel="5" imageModel="4" />
            </toolbarComponents>
            <components>
                <unknown />
                <button id="42" action="3" selectAction="4" tooltipModel="5" model="11" />
                <separator id="43" />
                <label id="44" model="6" />
                <list id="4" model="7" action="3" selectAction="4">
                    <properties><property id="6" value="100,0,*" /></properties>
                </list>
                <checkbox id="46" model="50" textModel="5" action="3">
                    <properties><property id="1" value="false">
                        <condition conditionType="LAYOUTBAG">
                            <assignments>
                                <assignment conditionValue="0" value="true" />
                                <assignment conditionValue="1" value="1" />
                            </assignments>
                        </condition>
                    </property></properties>
                </checkbox>
                <gauge id="47" textModel="5" model="8" action="3" changeAction="4" />
                <input id="48" textModel="5" resultModel="6" suggestModel="6" action="4" resultAction="3" suggestAction="3" />
                <image id="50" model="62"/>
                <button id="51" action="3" selectAction="4" imageModel="4" model="11" />
            </components>
        </toolbarHmiState>
        <popupHmiState id="49" textModel="11">
        </popupHmiState>
        <audioHmiState id="24" artistAction="21" coverAction="29" progressAction="37" playListAction="33" albumAction="25" textModel="44" alternativeTextModel="48" trackTextModel="47" playListProgressTextModel="50" playListTextModel="49" artistImageModel="54" artistTextModel="45" albumImageModel="55" albumTextModel="46" coverImageModel="56" playbackProgressModel="62" downloadProgressModel="63" currentTimeModel="51" elapsingTimeModel="52" playListFocusRowModel="59" providerLogoImageModel="57" statusBarImageModel="61" playListModel="58">
            <toolbarComponents>
                <button id="141" action="3" selectAction="4" tooltipModel="5" imageModel="4" />
            </toolbarComponents>
            <components></components>
        </audioHmiState>
        <calendarMonthHmiState id="27" dateModel="60" highlightListModel="74" action="37" changeAction="33"/>
        <calendarHmiState id="28" textModel="11">
            <components>
                <calendarDay id="29" action="37" appointmentListModel="74" dateModel="60"/>
            </components>
        </calendarHmiState>
    </hmiStates>
    <entryButton id="49" action="4" model="5" imageModel="4"/>
    <instrumentCluster id="145" playlistModel="7" detailsModel="74" useCaseModel="35" action="64" textModel="39" additionalTextModel="38" setTrackAction="65" iSpeechSupport="36" iSpeechText="37" skipForward="41" skipBackward="40"/>
    <events>
        <popupEvent id="1" target="49" priority="10"/>
        <actionEvent id="2" action="7"/>
        <actionEvent id="3" action="7"/>
        <notificationIconEvent id="4" imageIdModel="62"/>
        <popupEvent id="5" target="49" priority="10"/>
        <focusEvent id="6" targetModel="6"/>
        <multimediaInfoEvent id="7" textModel1="6" textModel2="12"/>
        <statusbarEvent id="8" textModel="12"/>
    </events>
</pluginApp></pluginApps>
""";

void main() {
  test('UI Description should parse without crashing', () {
    RHMIAppDescription.loadXml(input);
  });

  test('UI Description contains 5 states', () {
    final app = RHMIAppDescription.loadXml(input);
    expect(app.states.length, 6);
  });

  test('UI Description contains 17 models', () {
    final app = RHMIAppDescription.loadXml(input);
    expect(app.models.length, 17);
  });

  test('Each component is linked to its models', () {

  });
}