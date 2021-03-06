# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
 
describe Metar::Remark do

  context '.parse' do

    it 'should delegate to subclasses' do
      Metar::Remark.parse('21012').  should    be_a(Metar::TemperatureExtreme)
    end

    it 'should return nil for unrecognised' do
      Metar::Remark.parse('FOO').    should    be_nil
    end

    context '6-hour maximum or minimum' do

      [
        ['positive maximum', '10046', [:maximum,  4.6]],
        ['negative maximum', '11012', [:maximum, -1.2]],
        ['positive minimum', '20046', [:minimum,  4.6]],
        ['negative minimum', '21012', [:minimum, -1.2]],
      ].each do |docstring, raw, expected|
        example docstring do
          Metar::Remark.parse(raw).
                                should    be_temperature_extreme(*expected)
        end
      end

    end

    context '24-hour maximum and minimum' do

      it 'returns minimum and maximum' do
        max, min = Metar::Remark.parse('400461006')

        max.                      should    be_temperature_extreme(:maximum,  4.6)
        min.                      should    be_temperature_extreme(:minimum, -0.6)
      end

    end

    context 'pressure tendency' do

      it 'steady_then_decreasing' do
        pt = Metar::Remark.parse('58033')

        pt.                       should    be_a(Metar::PressureTendency)
        pt.character.             should    == :steady_then_decreasing
        pt.value.                 should    == 3.3
      end

    end

    context '3-hour and 6-hour precipitation' do

      it '60009' do
        pr = Metar::Remark.parse('60009')
        
        pr.                       should    be_a(Metar::Precipitation)
        pr.period.                should    == 3
        pr.amount.value.          should    == 0.002286
      end

    end

    context '24-hour precipitation' do

      it '70015' do
        pr = Metar::Remark.parse('70015')
        
        pr.                       should    be_a(Metar::Precipitation)
        pr.period.                should    == 24
        pr.amount.value.          should    == 0.003810
      end

    end

    context 'automated station' do

      [
        ['with precipitation dicriminator', 'AO1', [Metar::AutomatedStationType, :with_precipitation_discriminator]],
        ['without precipitation dicriminator', 'AO2', [Metar::AutomatedStationType, :without_precipitation_discriminator]],
      ].each do |docstring, raw, expected|
        example docstring do
          aut = Metar::Remark.parse(raw)

          aut.                      should    be_a(expected[0])
          aut.type.                 should    == expected[1]
        end
      end

    end

    context 'sea-level pressure' do

      it 'SLP125' do
        slp = Metar::Remark.parse('SLP125')

        slp.                      should    be_a(Metar::SeaLevelPressure)
        slp.pressure.value.       should    == 0.0125
      end

    end

    context 'hourly temperature and dew point' do

      it 'T00640036' do
        htm = Metar::Remark.parse('T00641036')

        htm.                      should    be_a(Metar::HourlyTemperaturAndDewPoint)
        htm.temperature.value.    should    ==  6.4
        htm.dew_point.value.      should    == -3.6
      end

    end

  end

end

describe Metar::Lightning do

  context '.parse_chunks' do

    [
      ['direction',                        'LTG SE',            [:default,      nil, ['SE']]],
      ['distance direction',               'LTG DSNT SE',       [:default, 16093.44, ['SE']]],
      ['distance direction and direction', 'LTG DSNT NE AND W', [:default, 16093.44, ['NE', 'W']]],
      ['distance direction-direction',     'LTG DSNT SE-SW',    [:default, 16093.44, ['SE', 'SW']]],
      ['distance all quandrants',          'LTG DSNT ALQDS',    [:default, 16093.44, ['N', 'E', 'S', 'W']]],
    ].each do |docstring, section, expected|
      example docstring do
        chunks = section.split(' ')
        r = Metar::Lightning.parse_chunks(chunks)

        r.                        should    be_a(Metar::Lightning)
        r.type.                   should    == expected[0]
        if expected[1]
          r.distance.value.       should    == expected[1]
        else
          r.distance.             should    be_nil
        end
        r.directions.             should    == expected[2]
      end
    end

    it 'should remove parsed chunks' do
      chunks = ['LTG', 'DSNT', 'SE', 'FOO']

      r = Metar::Lightning.parse_chunks(chunks)

      chunks.                     should    == ['FOO']
    end

    it 'should fail if the first chunk is not LTGnnn' do
      expect do
        Metar::Lightning.parse_chunks(['FOO'])
      end.                        to        raise_error(RuntimeError, /not lightning/)
    end

    it 'should not fail if all chunks are parsed' do
      chunks = ['LTG', 'DSNT', 'SE']

      r = Metar::Lightning.parse_chunks(chunks)

      chunks.                     should    == []
    end

  end

end

