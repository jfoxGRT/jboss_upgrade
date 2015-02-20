module SaplingsHelper

  SUPERNUMBER_JERBUL = "8860"
  SUPERNUMBER_AQUAGRILL = "2200000"
  SUPERNUMBER_BALTHAZAR = "3208000"
  SUPERNUMBER_CRAFT = "3608000"
  @@SUPERNUMBER_DUKE = "4108000"
  SUPERNUMBER_EATALY = "2.4.0.0.0"
  SUPERNUMBER_F = "2.5.0.0.0" # TODO: complete once next name is known. Fannelli's, maybe? 
  LOWERCASE_SNAPSHOT_SUFFIX = '-snapshot'

  module MAJOR_RELEASES
    JERBUL = 0
    AQUAGRILL = 1
    BALTHAZAR = 2
    CRAFT = 3
    DUKE = 4
    EATALY = 5
  end

  def self.get_duke_version
    @@SUPERNUMBER_DUKE
  end 

  def translate_sapling_state(pState)
    case pState
      when "p" then "Published"
  	when "a" then "Unpublished"
      when "d" then "Deployed"
      when "i" then "Inactive"
      else "Unknown"
    end
  end


  # utility method that handles the custom versioning scheme established by Release Engineering, adopted
  # in early 2014.
  # @see ProductLineUtils.compareReleaseVersions() (java class)
  def self.compare_release_versions(version1, version2, strict_mode=false)
    comparison_result = -99
    
    left = version1.downcase
    right = version2.downcase
    
    left_is_snapshot = left.include?(LOWERCASE_SNAPSHOT_SUFFIX)
    right_is_snapshot = right.include?(LOWERCASE_SNAPSHOT_SUFFIX)
    
    # temporarily remove the -SNAPSHOT, if any, so we can safely discard other hyphens and charaters
    left.gsub!(LOWERCASE_SNAPSHOT_SUFFIX, String.new) if left_is_snapshot
    right.gsub!(LOWERCASE_SNAPSHOT_SUFFIX, String.new) if right_is_snapshot
    
    left = strip_junk_from_version_string(left)
    right = strip_junk_from_version_string(right)
    
    # at this point, any dot-release version is considerd newer than any integral version from older releases
    left_is_legacy_version = false
    right_is_legacy_version = false
    unless strict_mode
      left_is_legacy_version = !left.include?('.')
      right_is_legacy_version = !right.include?('.')
    end
    
    # if one version is a legacy version and the other is not, we're done.
    if (left_is_legacy_version && !right_is_legacy_version)
      comparison_result = -1
    elsif (!left_is_legacy_version && right_is_legacy_version)
      comparison_result = 1
    else
      # if both are new versions or both are legacy versions, replace the snapshot tag and let compare_maven_versions() sort it out 
      left << LOWERCASE_SNAPSHOT_SUFFIX.upcase if left_is_snapshot
      right << LOWERCASE_SNAPSHOT_SUFFIX.upcase if right_is_snapshot
      
      comparison_result = compare_maven_versions(left, right)
    end
    
    comparison_result
  end


  # @see ProductLineUtils.compareMavenVersions() (java class)
  def self.compare_maven_versions(version1, version2)
    comparisonResult = -99
    
    if version1.nil? || version2.nil? || version1.empty? || version2.empty?
      raise 'cant compare null or empty version strings.'
    end
    
    leftIsSnapshot = version1.downcase.end_with?(LOWERCASE_SNAPSHOT_SUFFIX)
    rightIsSnapshot = version2.downcase.end_with?(LOWERCASE_SNAPSHOT_SUFFIX)
    
    # remove the -SNAPSHOT, if any from the end of the version string
    if leftIsSnapshot
      version1 = version1[0, version1.length - LOWERCASE_SNAPSHOT_SUFFIX.length]
    end
    if rightIsSnapshot
      version2 = version2[0, version2.length - LOWERCASE_SNAPSHOT_SUFFIX.length]
    end
    
    version1 = strip_junk_from_version_string(version1)
    version2 = strip_junk_from_version_string(version2)
    
    leftVersionObect = Gem::Version.new(version1)
    rightVersionObect = Gem::Version.new(version2)
    
    if leftVersionObect == rightVersionObect # iff the numerical component is equal, snapshot comes into play
      if(leftIsSnapshot && !rightIsSnapshot)
        comparisonResult = -1
      elsif(rightIsSnapshot && !leftIsSnapshot)
        comparisonResult = 1
      else
        comparisonResult = 0
      end
    elsif leftVersionObect > rightVersionObect
      comparisonResult = 1
    else
      comparisonResult = -1
    end
    
    return comparisonResult
  end
  
  
  # remove hypens, alpha characters, and any trailing .0 from version string.
  # ex. "10.0-dev" => "10"
  def self.strip_junk_from_version_string(version_string)
    cleaned_version_string = version_string.gsub('-', String.new)
    
    cleaned_version_string.gsub!(/[^0-9.]/, String.new)
    
    cleaned_version_string.chomp!('.0') while cleaned_version_string.end_with?('.0')
    
    cleaned_version_string
  end
  
  
  def self.get_major_release(version)
    if compare_release_versions(version, SUPERNUMBER_JERBUL) < 0
      return nil # we don't know about this version, it's too old
    elsif compare_release_versions(version, SUPERNUMBER_AQUAGRILL) < 0
      return MAJOR_RELEASES::JERBUL
    elsif compare_release_versions(version, SUPERNUMBER_BALTHAZAR) < 0
      return MAJOR_RELEASES::AQUAGRILL
    elsif compare_release_versions(version, SUPERNUMBER_CRAFT) < 0
      return MAJOR_RELEASES::BALTHAZAR
    elsif compare_release_versions(version, SUPERNUMBER_DUKE) < 0
      return MAJOR_RELEASES::CRAFT
    elsif compare_release_versions(version, SUPERNUMBER_EATALY) < 0
      return MAJOR_RELEASES::DUKE
    elsif compare_release_versions(version, SUPERNUMBER_F) < 0
      return MAJOR_RELEASES::EATALY
    else
      return nil # we don't know about this version, it's too recent
    end
  end
  
end
